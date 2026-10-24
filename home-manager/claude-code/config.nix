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
  permissionRules = import ../lib/permissions.nix {
    inherit lib;
    harness = "claude-code";
    rules = import ../../preferences/permissions;
  };
  rules = pkgs.callPackage ../lib/rules.nix {
    harness = "claude-code";
    src = cfg.rules;
  };
  hooks = pkgs.callPackage ../lib/hooks.nix { };
  hooksDir = pkgs.linkFarm "claude-code-hooks" {
    post-tool-use = lib.getExe (hooks.claude-code cfg.hooks.postToolUse);
  };
  linkedFiles = {
    "keybindings.json" = (pkgs.formats.json { }).generate "claude-code-keybindings.json" (
      import ../../claude-code/keybindings.nix
    );
    "CLAUDE.md" = cfg.instructions;
    inherit rules;
    hooks = hooksDir;
  }
  // lib.mapAttrs' (name: lib.nameValuePair "skills/${name}") cfg.skills;
  prune = pkgs.callPackage ../lib/prune.nix {
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
  globalConfigFile = "${
    config.home.sessionVariables.CLAUDE_CONFIG_DIR or config.home.homeDirectory
  }/.claude.json";
  setGlobalConfig = pkgs.callPackage ../lib/managed-merge.nix {
    harness = "claude-code";
    values = import ../../claude-code/global-config.nix;
  };
in
{
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
      settings = import ../../claude-code/settings.nix {
        inherit (claudeCode) configDir;
        inherit permissionRules;
      };
    };

    home.file =
      lib.mapAttrs' (
        path: source:
        lib.nameValuePair "${claudeCode.configDir}/${path}" {
          inherit source;
          force = true;
        }
      ) linkedFiles
      // {
        "${claudeCode.configDir}/settings.json".force = true;
      };

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
