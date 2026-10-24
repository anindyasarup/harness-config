# 1. Versioning

## Context

Other flakes pin harness-config by tag, and Nix doesn't resolve version
ranges. A version number is only a message to a consumer about whether they can
update without reading anything. The commit types (`add`, `update`, `rename`,
`bump`) describe what changed in the repo, not what a consumer sees, so they
can't decide the bump on their own.

## Decision

Tags are plain semver without a `v` (`1.0.0`). Each release takes the highest
level among its changes.

Semver covers the interface: the flake outputs, the `harness.claude-code.*`
and `harness.omp.*` options and their types, the hook check names, the paths in
the Claude config directory and the omp agent folder that are replaced or
pruned, and the supported claude-code and home-manager versions. The defaults
(preferences, settings, keybindings, default skills and default hooks) are
opinions that can change in a minor release.

Major, when an existing consumer config fails to build, loses files, or needs
an edit to keep working the same:

- A flake output or option is removed or renamed, or an option's type changes.
- A hook check name is removed.
- A new path in the Claude config directory or the omp agent folder is
  replaced or pruned.
- `minVersion`, the required home-manager, or a new assertion rejects configs
  that used to build.

Minor:

- New flake outputs, options, hook checks or harness modules.
- New warnings.
- Changes to `preferences/`, `claude-code/settings.nix`,
  `claude-code/keybindings.nix`, the default skills or the default hooks.
- Bumps to the humanizer and mattpocock-skills inputs, because they change the
  prompt text the agent runs on.

Patch: bug fixes, clearer errors for setups that already failed, and README
changes. Tests, the justfile, `dev/` and `.claude/` don't affect consumers and
don't need a release.

A rename goes through `lib.mkRenamedOptionModule`, so the old name keeps
working with a warning until the next major. That makes it a minor change.

`just interface-diff <tag>` lists the outputs, options with their types, and
replaced paths that changed since a tag. The pruned paths aren't in that list,
so a release also checks the prune `paths`, `dirs` and `keep` in
`home-manager/claude-code/config.nix` and `home-manager/omp/config.nix`.

`CHANGELOG.md` gets one entry per release, written at release time from
`git log <tag>..HEAD`. It lists only what a consumer notices, under Breaking
(with what to edit), Added, Changed and Fixed.

## Consequences

- Most preference changes are minor, so a minor release can change how the
  agent behaves. Consumers who want to review that read the changelog.
- Pruning a new path is always major, because it deletes files.
- Reshaping options for more harnesses either waits for 2.0.0 or keeps the old
  names through `mkRenamedOptionModule`.
