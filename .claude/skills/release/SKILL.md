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
   `home-manager/claude-code/config.nix` or `home-manager/omp/config.nix`
   changed; a newly pruned path is major.
4. Give every commit a level (major, minor, patch, or none) with a one-line
   reason. Mark any commit you can't place, and say why.
5. The version is the last tag bumped by the highest level.
6. Add the entry at the top of `CHANGELOG.md`, under `## <version>`, with the
   Breaking, Added, Changed and Fixed sections that apply. Breaking entries say
   what the consumer has to edit. Leave out changes with level none. Run
   `/humanizer` on the entry.
7. Show the per-commit levels, the version and the entry, then wait for the
   user's review. The user runs every command that publishes the release.
8. Once the user approves the entry, write the release notes to a temporary
   file: the entry without its `## <version>` heading, with each bullet on one
   line, because GitHub renders a line break inside a bullet. Give the user
   these commands to run, in order:

   ```sh
   git commit -m "add(changelog): <version>" -- CHANGELOG.md
   git tag <version>
   git push && git push origin <version>
   gh release create <version> --title <version> --notes-file <notes> --verify-tag
   ```

   The `-- CHANGELOG.md` pathspec keeps other work in the tree out of the
   release commit. The release is done when `gh release list` shows `<version>`
   as Latest.
