{ configDir }:
{
  model = "sonnet";
  effortLevel = "medium";

  permissions.defaultMode = "default";

  theme = "auto";

  tui = "fullscreen";
  editorMode = "normal";
  autoScrollEnabled = true;

  autoMemoryEnabled = false;
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
            command = "${configDir}/hooks/post-tool-use";
          }
        ];
      }
    ];
  };

}
