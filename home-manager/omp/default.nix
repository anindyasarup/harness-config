{ humanizer, mattpocock-skills }:
{ lib, pkgs, ... }:
let
  hooks = pkgs.callPackage ../lib/hooks.nix { };
in
{
  imports = [ ./config.nix ];

  options.harness.omp = {
    enable = lib.mkEnableOption ''
      omp with these instructions, rules, skills, hooks and settings. Replaces AGENTS.md,
      rules/, hooks/, keybindings.yml, extensions/harness-read-guard.ts and the skills it links, and merges the keys from omp/settings.nix into
      config.yml in the agent folder at PI_CODING_AGENT_DIR or ~/.omp/agent,
      keeping the rest. Activation deletes agents/, commands/ and every skill it doesn't link
    '';

    instructions = lib.mkOption {
      type = lib.types.path;
      default = ../../preferences/AGENTS.md;
      defaultText = lib.literalExpression "harness-config's preferences/AGENTS.md";
      description = "Global instructions, linked as AGENTS.md.";
    };

    rules = lib.mkOption {
      type = lib.types.path;
      default = ../../preferences/instructions/rules;
      defaultText = lib.literalExpression "harness-config's preferences/instructions/rules";
      description = "Directory of rule files, each with paths: frontmatter, linked as rules/. omp applies each rule when it edits or writes a file its paths match.";
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = import ../lib/skills.nix { inherit lib humanizer mattpocock-skills; };
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
}
