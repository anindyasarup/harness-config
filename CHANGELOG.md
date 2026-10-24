# Changelog

Versions follow [docs/adr/0001-versioning.md](docs/adr/0001-versioning.md).

## 1.3.0

### Added

- `harness.omp.enable` creates omp's agent folder at `~/.omp/agent`, or at
  `PI_CODING_AGENT_DIR` when set. It manages nothing inside it yet.
- Activation records the `.claude.json` keys it sets in
  `.claude.json.managed-keys.json`. When a release stops setting a key, the
  next activation removes it and claude-code falls back to its own default.
  Activation leaves keys you set yourself alone, and the first one has no
  record, so it removes nothing. The README shows how to clear the managed
  keys by hand after turning off `harness.claude-code.enable`.

### Changed

- `preferences/AGENTS.md` tells the agent to give you a denied command to run
  rather than work around it.
- The README lists omp as in progress.

## 1.2.1

### Fixed

- claude-code opens agent view by default. Since 1.1.0 the setting sat in
  `settings.json`, where claude-code ignores it. Activation now writes
  `defaultToAgentsView` and `remoteControlAtStartup` to `.claude.json` and
  leaves its other keys alone.

## 1.2.0

### Added

- The README shows how to pin or swap the `humanizer` or `mattpocock-skills`
  input from your own flake.

### Changed

- mattpocock-skills moves to `49dd158`, which brings upstream fixes to the
  `wizard` skill's script template. The other skills are unchanged.

## 1.1.0

### Added

- `darwinModules.default` and `nixosModules.default` add the home module to
  `home-manager.sharedModules`. Import home-manager's own system module next to
  them.
- Builds warn when `programs.claude-code.package` is null, because the
  claude-code version check can't run then.

### Changed

- claude-code opens agent view by default (`defaultToAgentsView`).
- claude-code reads both `CLAUDE.md` and `AGENTS.md` in projects.

### Fixed

- On stable home-manager the build fails with "harness-config needs
  home-manager unstable" instead of a missing-attribute error.
- The README says claude-code is unfree and shows the `allowUnfreePredicate`
  setting.

## 1.0.0

First release, with claude-code support.
