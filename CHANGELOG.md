# Changelog

Versions follow [docs/adr/0001-versioning.md](docs/adr/0001-versioning.md).

## 2.0.0

claude-code now starts in auto mode (`permissions.defaultMode = "auto"`). A
classifier approves most actions without asking, and harness-config's
permission rules decide what still asks or is refused.

### Breaking

- With `harness.omp.enable`, activation manages more of omp's agent folder. It
  replaces `AGENTS.md`, `rules/`, `hooks/`, `keybindings.yml` and each linked
  `skills/<name>`. It deletes `agents/`, `commands/` and every skill it doesn't
  link. Before updating, move skills you added by hand to `~/.agents/skills`,
  which omp also reads and harness-config leaves alone.
  Copy anything you want to keep from `agents/`, `commands/`, `hooks/` and
  `keybindings.yml` somewhere else. To keep your own instructions or rules,
  set `harness.omp.instructions` or `harness.omp.rules` to them.

### Added

- `harness.omp.instructions` (default `preferences/AGENTS.md`) is linked as
  `AGENTS.md` in omp's agent folder.
- `harness.omp.skills` (default: the same skills as claude-code) links each
  skill as `skills/<name>`. omp skips a skill whose `SKILL.md` has no
  `description`.
- `harness.omp.rules` (default `preferences/instructions/rules`) is linked as
  `rules/`. Each rule's `paths:` becomes a scope on omp's edit and write tools,
  so omp loads a rule the first time it edits or writes a matching file.
- `harness.omp.hooks.postToolUse` (default `no-comments` and `no-emdash`) runs
  claude-code's checks on the text omp adds with its write and edit tools. A
  failed check turns the tool result into an error with the reason.
- omp gets an empty `keybindings.yml`, so both harnesses keep their default
  keys.

### Changed

- claude-code gets permission rules for git, nix, installs, files outside the
  repo, network, and build and test runners. Each rule lets a command run
  without asking, asks first, or refuses it. Asking and refusing hold in every
  permission mode. For example, `git push`, `git merge` and `nix build` ask.
  `git push --force`, `git reset --hard`, global installs (`npm`,
  `brew install`, `pip install`, `cargo install`), `home-manager switch`,
  `nix flake update`, `sudo`, reading `~/.ssh` or `~/.aws`, and piping a
  download into a shell are refused. Rules that depend on context, such as
  "outside the repo", go to the auto mode classifier as prose, on top of its
  built-in rules. The rules can't be turned off.
- claude-code denies the `AskUserQuestion`, `SendFeedback`, `EnterWorktree` and
  `ListAgents` tools, and no longer syncs plugins from claude.ai.

## 1.5.0

### Added

- `harness.omp.model` sets omp's default model to a provider and one of its
  models, such as
  `{ provider = "github-copilot"; model = "claude-sonnet-4.5"; }`.
  Activation writes it to `modelRoles.default` in `config.yml` as
  `provider/model` and leaves claude-code's model as it is. With the option
  unset (the default), activation leaves omp's model alone and removes any
  model it set earlier.
- The README has a GitHub Copilot example and says how to log in to the
  provider.

## 1.4.0

### Added

- With `harness.omp.enable`, activation sets omp's `defaultThinkingLevel` to
  `medium` and `tools.approvalMode` to `always-ask` in `config.yml`, matching
  claude-code's effort level and default permission mode. Activation keeps
  every other key in the file and creates the file if it's missing. If the
  file isn't valid YAML, activation fails and leaves it alone. As with
  `.claude.json`, activation lists the keys it set in
  `config.yml.managed-keys.json` and removes any that a later release stops
  setting.
- The README lists the claude-code settings omp has no equivalent for, and
  shows how to clear omp's managed keys after turning omp off.

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
