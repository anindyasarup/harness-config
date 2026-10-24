# files outside the repo

## Don't ask

- Write `$CLAUDE_JOB_DIR/tmp`, `/tmp`

## Ask

- `ls`, `cat`, `head`, `tail`, `rg`, `fd`, `find` outside the repo
- Read `/nix/store`
- Edit, Write outside the repo
- `cp`, `mv`, `mkdir`, `touch` outside the repo

## Never do

- Read `~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.config/gh/hosts.yml`, `~/.netrc`
- Read `.env`, `.env.*` outside the repo
- Edit files home-manager manages: `~/.claude/settings.json`, `~/.zshrc`,
  `~/.config/*`
- Edit `/etc`, `/nix/store`, `/Library`, `/System`
- `rm`, `rm -rf` outside the repo
- `chmod`, `chown` outside the repo
- `sudo`
