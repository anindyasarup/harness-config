let
  paths =
    verdict: kind:
    map (path: {
      inherit verdict;
      ${kind} = path;
    });
  prose =
    verdict:
    map (prose: {
      inherit verdict prose;
    });
in
paths "dont-ask" "edit" [
  "//tmp/**"
]
++ prose "dont-ask" [
  "Writing files in the job's temporary folder, `$CLAUDE_JOB_DIR/tmp`."
]
++ prose "ask" [
  "Reading or listing files outside the repo, including with `ls`, `cat`, `head`, `tail`, `rg`, `fd` or `find`."
  "Editing or writing files outside the repo."
  "Copying, moving or creating files or folders outside the repo with `cp`, `mv`, `mkdir` or `touch`."
]
++ paths "ask" "read" [
  "//nix/store/**"
]
++ paths "never-do" "read" [
  "~/.ssh/**"
  "~/.gnupg/**"
  "~/.aws/**"
  "~/.config/gh/hosts.yml"
  "~/.netrc"
]
++ prose "never-do" [
  "Reading `.env` or `.env.*` files outside the repo."
  "Removing files outside the repo with `rm` or `rm -rf`."
  "Changing permissions or ownership outside the repo with `chmod` or `chown`."
]
++ paths "never-do" "edit" [
  "~/.claude/settings.json"
  "~/.zshrc"
  "~/.config/**"
  "//etc/**"
  "//nix/store/**"
  "//Library/**"
  "//System/**"
  "~/.ssh/**"
]
++ [
  {
    verdict = "never-do";
    command = "sudo";
  }
]
