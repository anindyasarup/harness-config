{ humanizer, mattpocock-skills }:
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
  permissionRules = import ./lib/permissions.nix {
    inherit lib;
    harness = "omp";
    rules = import ../preferences/permissions;
  };
  settings =
    lib.recursiveUpdate (import ../omp/settings.nix) permissionRules.settings
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
  hooks = pkgs.callPackage ./lib/hooks.nix { };
  readGuard = pkgs.replaceVars ../omp/extensions/read-guard.ts {
    neverDoReads = builtins.toJSON permissionRules.neverDoReads;
    git = lib.getExe pkgs.git;
  };
  rules = pkgs.callPackage ./lib/rules.nix {
    harness = "omp";
    src = cfg.rules;
  };
  prune = pkgs.callPackage ./lib/prune.nix {
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
in
{
  options.harness.omp = {
    enable = lib.mkEnableOption ''
      omp with these instructions, rules, skills, hooks and settings. Replaces AGENTS.md,
      rules/, hooks/, keybindings.yml, extensions/harness-read-guard.ts and the skills it links, and merges the keys from omp/settings.nix into
      config.yml in the agent folder at PI_CODING_AGENT_DIR or ~/.omp/agent,
      keeping the rest. Activation deletes agents/, commands/ and every skill it doesn't link
    '';

    instructions = lib.mkOption {
      type = lib.types.path;
      default = ../preferences/AGENTS.md;
      defaultText = lib.literalExpression "harness-config's preferences/AGENTS.md";
      description = "Global instructions, linked as AGENTS.md.";
    };

    rules = lib.mkOption {
      type = lib.types.path;
      default = ../preferences/instructions/rules;
      defaultText = lib.literalExpression "harness-config's preferences/instructions/rules";
      description = "Directory of rule files, each with paths: frontmatter, linked as rules/. omp applies each rule when it edits or writes a file its paths match.";
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = import ./lib/skills.nix { inherit lib humanizer mattpocock-skills; };
      defaultText = lib.literalExpression "{ humanizer = <github:blader/humanizer>; } // <the skills in github:mattpocock/skills's Claude Code plugin>";
      description = "Skill directories, each linked as skills/<name>. omp skips a skill whose SKILL.md has no description.";
    };

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

    hooks.postToolUse = lib.mkOption {
      type = lib.types.listOf (lib.types.enum hooks.checkNames);
      default = [
        "no-comments"
        "no-emdash"
      ];
      description = "Checks run, in order, on the text omp adds with write or edit. When a check fails, the tool result becomes an error with the check's reason added.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      "${agentDir}/AGENTS.md" = {
        source = cfg.instructions;
        force = true;
      };
      "${agentDir}/rules" = {
        source = rules;
        force = true;
      };
      "${agentDir}/hooks" = {
        source = hooks.omp cfg.hooks.postToolUse;
        force = true;
      };
      "${agentDir}/keybindings.yml" = {
        source = (pkgs.formats.yaml { }).generate "omp-keybindings.yml" { };
        force = true;
      };
      "${agentDir}/extensions/harness-read-guard.ts" = {
        source = readGuard;
        force = true;
      };
    }
    // lib.mapAttrs' (
      name: source:
      lib.nameValuePair "${agentDir}/skills/${name}" {
        inherit source;
        force = true;
      }
    ) cfg.skills;

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
