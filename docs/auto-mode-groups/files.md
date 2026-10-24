# files outside the repo

## Don't ask

- `ls`, `cat`, `head`, `tail`, `rg`, `fd`, `find` outside the repo
- Read `/nix/store`
- Write `$CLAUDE_JOB_DIR/tmp`

## Ask

- Edit, Write outside the repo
- `cp`, `mv`, `mkdir`, `touch` outside the repo
- Write `/tmp`

## Never do

- Read `~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.config/gh/hosts.yml`, `~/.netrc`
- Read `.env`, `.env.*` outside the repo
- Edit files home-manager manages: `~/.claude/settings.json`, `~/.zshrc`,
  `~/.config/*`
- Edit `/etc`, `/nix/store`, `/Library`, `/System`
- `rm`, `rm -rf` outside the repo
- `chmod`, `chown` outside the repo
- `sudo`
