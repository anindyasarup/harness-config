{
  model = "sonnet";
  effortLevel = "medium";

  permissions.defaultMode = "default";

  theme = "auto";

  tui = "fullscreen";
  editorMode = "normal";
  autoScrollEnabled = true;

  remoteControlAtStartup = false;

  attribution = {
    commit = "";
    pr = "";
  };

  worktree.bgIsolation = "none";

  hooks = {
    PostToolUse = [
      {
        matcher = "Write|Edit|MultiEdit|NotebookEdit";
        hooks = [
          {
            type = "command";
            command = "$HOME/.claude/hooks/post-tool-use";
          }
        ];
      }
    ];
  };

}
