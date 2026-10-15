---
name: release
description: "Use when preparing a harness-config release: picks the semver bump and writes the CHANGELOG.md entry."
---

# Release

The rules are in `docs/adr/0001-versioning.md`. Read it first.

1. Find the last tag with `git describe --tags --abbrev=0`.
2. Read `git log <tag>..HEAD` and the diff of each commit.
3. Run `just interface-diff <tag>`. A removed or retyped line is major. Also
   check whether the prune `paths`, `dirs` or `keep` in
   `home-manager/claude-code.nix` changed; a newly pruned path is major.
4. Give every commit a level (major, minor, patch, or none) with a one-line
   reason. Mark any commit you can't place, and say why.
5. The version is the last tag bumped by the highest level.
6. Add the entry at the top of `CHANGELOG.md`, under `## <version>`, with the
   Breaking, Added, Changed and Fixed sections that apply. Breaking entries say
   what the consumer has to edit. Leave out changes with level none. Run
   `/humanizer` on the entry.
7. Stop and show the per-commit levels, the version and the entry. Don't
   commit, tag or push.
