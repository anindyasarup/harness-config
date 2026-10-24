{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.harness.omp;
  agentDir =
    config.home.sessionVariables.PI_CODING_AGENT_DIR or "${config.home.homeDirectory}/.omp/agent";
  settings =
    import ../omp/settings.nix
    // lib.optionalAttrs (cfg.model != null) {
      modelRoles.default = "${cfg.model.provider}/${cfg.model.model}";
    };
  managedSettingsKeys = lib.collect lib.isList (
    lib.mapAttrsRecursiveCond (value: value != { }) (path: _: path) settings
  );
  managedSettingsKeysFile =
    (pkgs.formats.json { }).generate "omp-settings-keys.json"
      managedSettingsKeys;
  mergeSettings = pkgs.writeText "omp-merge-settings.yq" ''
    with(select(tag == "!!null"); . = {})
    | with(select(tag != "!!map"); error("the root of " + filename + " is not a mapping"))
    | delpaths(env(PREVIOUS_KEYS) - load("${managedSettingsKeysFile}")) * load("${
      (pkgs.formats.yaml { }).generate "omp-settings.yml" settings
    }")
  '';
  setSettings = pkgs.writeShellApplication {
    name = "omp-set-settings";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.yq-go
    ];
    text = ''
      file=$1
      record="$file.managed-keys.json"
      mkdir -p "$(dirname "$file")"
      touch "$file"
      previous_keys=$(cat "$record" 2>/dev/null || echo '[]')
      updated=$(mktemp "$file.XXXXXX")
      trap 'rm -f "$updated"' EXIT
      PREVIOUS_KEYS="$previous_keys" yq --from-file ${mergeSettings} "$file" > "$updated"
      mv "$updated" "$file"
      updated_record=$(mktemp "$record.XXXXXX")
      cat ${managedSettingsKeysFile} > "$updated_record"
      mv "$updated_record" "$record"
    '';
  };
in
{
  options.harness.omp = {
    enable = lib.mkEnableOption ''
      omp with these settings. Merges the keys from omp/settings.nix into
      config.yml in the agent folder at PI_CODING_AGENT_DIR or ~/.omp/agent,
      keeping the rest
    '';

    model = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            provider = lib.mkOption {
              type = lib.types.str;
              example = "github-copilot";
              description = "omp provider id.";
            };
            model = lib.mkOption {
              type = lib.types.str;
              example = "claude-sonnet-4.5";
              description = "Model id the provider offers.";
            };
          };
        }
      );
      default = null;
      description = "omp's default model, written to modelRoles.default as provider/model. Null leaves omp's model alone. Claude Code's model is unaffected.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.setOmpSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe setSettings} ${lib.escapeShellArg "${agentDir}/config.yml"}
    '';
  };
}
