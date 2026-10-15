# Changelog

Versions follow [docs/adr/0001-versioning.md](docs/adr/0001-versioning.md).

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
