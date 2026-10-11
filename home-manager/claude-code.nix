{ humanizer, mattpocock-skills }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  mattpocockPlugin = lib.importJSON "${mattpocock-skills}/.claude-plugin/plugin.json";
  mattpocockSkills = lib.listToAttrs (
    map (
      path: lib.nameValuePair (baseNameOf path) "${mattpocock-skills}/${lib.removePrefix "./" path}"
    ) (lib.filter (path: baseNameOf path != "code-review") mattpocockPlugin.skills)
  );
  cfg = config.harness.claude-code;
  claudeCode = config.programs.claude-code;
  minVersion = "2.1.280";
  hooks = pkgs.callPackage ./lib/hooks.nix { };
  hooksDir = pkgs.linkFarm "claude-code-hooks" {
    post-tool-use = lib.getExe (hooks.claude-code cfg.hooks.postToolUse);
  };
  rules = pkgs.callPackage ./lib/rules.nix {
    harness = "claude-code";
    src = cfg.rules;
  };
  prune = pkgs.callPackage ./lib/prune.nix {
    harness = "claude-code";
    paths = [
      "CLAUDE.md"
      "rules"
      "hooks"
    ];
    dirs = [ "skills" ];
    keep = [ "skills/synced" ];
  };
in
{
  options.harness.claude-code = {
    enable = lib.mkEnableOption ''
      Claude Code with these instructions, rules, skills and hooks. Replaces
      settings.json, CLAUDE.md, rules/, hooks/ and every skill in the Claude config directory
      except skills/synced; anything else there is deleted on activation
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
      default = {
        inherit humanizer;
      }
      // mattpocockSkills;
      defaultText = lib.literalExpression "{ humanizer = <github:blader/humanizer>; } // <the skills in github:mattpocock/skills's Claude Code plugin, except code-review>";
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
    ];

    programs.claude-code = {
      enable = true;
      package = lib.mkDefault pkgs.claude-code;
      settings = import ../claude-code/settings.nix { inherit (claudeCode) configDir; };
    };

    home.file = {
      "${claudeCode.configDir}/settings.json".force = true;
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

    home.activation.pruneClaudeConfig =
      lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
        ''
          run ${lib.getExe prune} ${lib.escapeShellArg claudeCode.configDir}
        '';
  };
}
