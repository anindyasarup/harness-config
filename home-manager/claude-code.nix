{ humanizer, mattpocock-skills }:
{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.harness.claude-code;
  claudeCode = config.programs.claude-code;
  minVersion = "2.1.280";
  hooks = pkgs.callPackage ./lib/hooks.nix { };
  hooksDir = pkgs.linkFarm "claude-code-hooks" {
    post-tool-use = lib.getExe (hooks.claude-code cfg.hooks.postToolUse);
  };
  globalConfig = import ../claude-code/global-config.nix;
  managedGlobalConfigKeys = lib.collect lib.isList (
    lib.mapAttrsRecursiveCond (value: value != { }) (path: _: path) globalConfig
  );
  globalConfigFile = "${
    config.home.sessionVariables.CLAUDE_CONFIG_DIR or config.home.homeDirectory
  }/.claude.json";
  setGlobalConfig = pkgs.writeShellApplication {
    name = "claude-code-set-global-config";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      file=$1
      record="$file.managed-keys.json"
      touch "$file"
      previous_keys=$(cat "$record" 2>/dev/null || echo '[]')
      updated=$(mktemp "$file.XXXXXX")
      jq --slurp --argjson previous_keys "$previous_keys" --slurpfile settings ${
        (pkgs.formats.json { }).generate "claude-code-global-config.json" globalConfig
      } '((.[0] // {}) | delpaths($previous_keys)) * $settings[0]' "$file" > "$updated"
      mv "$updated" "$file"
      updated_record=$(mktemp "$record.XXXXXX")
      cat ${
        (pkgs.formats.json { }).generate "claude-code-global-config-keys.json" managedGlobalConfigKeys
      } > "$updated_record"
      mv "$updated_record" "$record"
    '';
  };
  rules = pkgs.callPackage ./lib/rules.nix {
    harness = "claude-code";
    src = cfg.rules;
  };
  permissionRules = import ./lib/permissions.nix {
    inherit lib;
    harness = "claude-code";
    rules = import ../preferences/permissions;
  };
  prune = pkgs.callPackage ./lib/prune.nix {
    harness = "claude-code";
    paths = [
      "CLAUDE.md"
      "rules"
      "hooks"
      "agents"
      "commands"
      "output-styles"
    ];
    dirs = [ "skills" ];
    keep = [ "skills/synced" ];
  };
in
{
  options.harness.claude-code = {
    enable = lib.mkEnableOption ''
      Claude Code with these instructions, rules, skills and hooks. Replaces
      settings.json, keybindings.json, CLAUDE.md, rules/, hooks/ and every skill in the
      Claude config directory except skills/synced; anything else there, and agents/,
      commands/ and output-styles/, is deleted on activation
    '';

    instructions = lib.mkOption {
      type = lib.types.path;
      default = ../preferences/AGENTS.md;
      defaultText = lib.literalExpression "harness-config's preferences/AGENTS.md";
      description = "Global instructions, linked as CLAUDE.md.";
    };

    rules = lib.mkOption {
      type = lib.types.path;
      default = ../preferences/instructions/rules;
      defaultText = lib.literalExpression "harness-config's preferences/instructions/rules";
      description = "Directory of rule files, each with paths: frontmatter, linked as rules/.";
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = import ./lib/skills.nix { inherit lib humanizer mattpocock-skills; };
      defaultText = lib.literalExpression "{ humanizer = <github:blader/humanizer>; } // <the skills in github:mattpocock/skills's Claude Code plugin>";
      description = "Skill directories, each linked as skills/<name>.";
    };

    hooks.postToolUse = lib.mkOption {
      type = lib.types.listOf (lib.types.enum hooks.checkNames);
      default = [
        "no-comments"
        "no-emdash"
      ];
      description = "Checks run, in order, on the text Claude adds with Write, Edit, MultiEdit or NotebookEdit.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          claudeCode.package == null || lib.versionAtLeast (lib.getVersion claudeCode.package) minVersion;
        message = "harness-config targets claude-code >= ${minVersion}, got ${lib.getVersion claudeCode.package}";
      }
      {
        assertion = options.programs.claude-code ? mutableSettings;
        message = "harness-config needs home-manager unstable: this release has no programs.claude-code.mutableSettings";
      }
      {
        assertion = !(claudeCode.mutableSettings or false);
        message = "harness-config replaces settings.json, so programs.claude-code.mutableSettings must be false; it would keep settings removed from claude-code/settings.nix";
      }
    ];

    warnings =
      lib.optional (claudeCode.package == null)
        "harness-config skips the claude-code version check (>= ${minVersion}) because programs.claude-code.package is null. Set it to run the check, and remove claude-code from home.packages if it's there.";

    programs.claude-code = {
      enable = true;
      package = lib.mkDefault null;
      settings = import ../claude-code/settings.nix {
        inherit (claudeCode) configDir;
        inherit permissionRules;
      };
    };

    home.file = {
      "${claudeCode.configDir}/settings.json".force = true;
      "${claudeCode.configDir}/keybindings.json" = {
        source = (pkgs.formats.json { }).generate "claude-code-keybindings.json" (
          import ../claude-code/keybindings.nix
        );
        force = true;
      };
      "${claudeCode.configDir}/CLAUDE.md" = {
        source = cfg.instructions;
        force = true;
      };
      "${claudeCode.configDir}/rules" = {
        source = rules;
        force = true;
      };
      "${claudeCode.configDir}/hooks" = {
        source = hooksDir;
        force = true;
      };
    }
    // lib.mapAttrs' (
      name: source:
      lib.nameValuePair "${claudeCode.configDir}/skills/${name}" {
        inherit source;
        force = true;
      }
    ) cfg.skills;

    home.activation = {
      pruneClaudeConfig = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        run ${lib.getExe prune} ${lib.escapeShellArg claudeCode.configDir}
      '';
      setClaudeGlobalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getExe setGlobalConfig} ${lib.escapeShellArg globalConfigFile}
      '';
    };
  };
}
