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
  permissionRules = import ../lib/permissions.nix {
    inherit lib;
    harness = "omp";
    rules = import ../../preferences/permissions;
  };
  rules = pkgs.callPackage ../lib/rules.nix {
    harness = "omp";
    src = cfg.rules;
  };
  hooks = pkgs.callPackage ../lib/hooks.nix { };
  readGuard = pkgs.replaceVars ../../omp/extensions/read-guard.ts {
    neverDoReads = builtins.toJSON permissionRules.neverDoReads;
    git = lib.getExe pkgs.git;
  };
  linkedFiles = {
    "AGENTS.md" = cfg.instructions;
    inherit rules;
    hooks = hooks.omp cfg.hooks.postToolUse;
    "keybindings.yml" = (pkgs.formats.yaml { }).generate "omp-keybindings.yml" { };
    "extensions/harness-read-guard.ts" = readGuard;
  }
  // lib.mapAttrs' (name: lib.nameValuePair "skills/${name}") cfg.skills;
  prune = pkgs.callPackage ../lib/prune.nix {
    harness = "omp";
    paths = [
      "AGENTS.md"
      "rules"
      "hooks"
      "agents"
      "commands"
    ];
    dirs = [ "skills" ];
  };
  settings =
    lib.recursiveUpdate (import ../../omp/settings.nix) permissionRules.settings
    // lib.optionalAttrs (cfg.model != null) {
      modelRoles.default = "${cfg.model.provider}/${cfg.model.model}";
    };
  setSettings = pkgs.callPackage ../lib/managed-merge.nix {
    harness = "omp";
    values = settings;
  };
in
{
  config = lib.mkIf cfg.enable {
    home.file = lib.mapAttrs' (
      path: source:
      lib.nameValuePair "${agentDir}/${path}" {
        inherit source;
        force = true;
      }
    ) linkedFiles;

    home.activation = {
      pruneOmpConfig = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        run ${lib.getExe prune} ${lib.escapeShellArg agentDir}
      '';
      setOmpSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getExe setSettings} ${lib.escapeShellArg "${agentDir}/config.yml"}
      '';
    };
  };
}
