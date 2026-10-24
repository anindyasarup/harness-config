{ configDir }:
{
  model = "sonnet";
  effortLevel = "medium";

  permissions.defaultMode = "default";
  permissions.deny = [
    "AskUserQuestion"
    "SendFeedback"
    "EnterWorktree"
    "ListAgents"
  ];

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
