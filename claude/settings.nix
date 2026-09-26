{
  model = "sonnet";
  effortLevel = "medium";

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
            command = "<some-path-or-symlink-here>/hooks/check-no-comments.sh";
          }
        ];
      }
    ];
  };

  permissions.defaultMode = "default";
}
