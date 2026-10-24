{ configDir, permissionRules }:
{
  model = "sonnet";
  effortLevel = "medium";

  permissions = permissionRules.permissions // {
    defaultMode = "default";
    deny = [
      "AskUserQuestion"
      "SendFeedback"
      "EnterWorktree"
      "ListAgents"
    ]
    ++ permissionRules.permissions.deny;
  };
  inherit (permissionRules) autoMode;

  theme = "auto";

  tui = "fullscreen";
  editorMode = "normal";
  autoScrollEnabled = true;

  autoMemoryEnabled = false;

  syncClaudeAiPlugins = false;

  attribution = {
    commit = "";
    pr = "";
  };

  worktree.bgIsolation = "none";

  pluginConfigs."cc-plugin-agents-md@builtin".options.instructionFiles = "claude-md-and-agents-md";

  hooks = {
    PostToolUse = [
      {
        matcher = "Write|Edit|MultiEdit|NotebookEdit";
        hooks = [
          {
            type = "command";
            command = "${configDir}/hooks/post-tool-use";
          }
        ];
      }
    ];
  };

}
