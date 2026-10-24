{ humanizer, mattpocock-skills }:
{ lib, pkgs, ... }:
let
  hooks = pkgs.callPackage ../lib/hooks.nix { };
in
{
  imports = [ ./config.nix ];

  options.harness.claude-code = {
    enable = lib.mkEnableOption ''
      Claude Code with these instructions, rules, skills and hooks. Replaces
      settings.json, keybindings.json, CLAUDE.md, rules/, hooks/ and every skill in the
      Claude config directory except skills/synced; anything else there, and agents/,
      commands/ and output-styles/, is deleted on activation
    '';

    instructions = lib.mkOption {
      type = lib.types.path;
      default = ../../preferences/AGENTS.md;
      defaultText = lib.literalExpression "harness-config's preferences/AGENTS.md";
      description = "Global instructions, linked as CLAUDE.md.";
    };

    rules = lib.mkOption {
      type = lib.types.path;
      default = ../../preferences/instructions/rules;
      defaultText = lib.literalExpression "harness-config's preferences/instructions/rules";
      description = "Directory of rule files, each with paths: frontmatter, linked as rules/.";
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = import ../lib/skills.nix { inherit lib humanizer mattpocock-skills; };
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
}
