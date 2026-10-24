# 2. omp config ownership

## Context

harness-config is adding oh-my-pi (omp) as a second harness next to Claude
Code. omp mirrors the Claude Code integration piece for piece, but some of
omp's behaviour forces a different way of owning its files, and those choices
need to be settled before the omp capabilities land one release at a time.

Claude Code's `settings.json` is a read-only Nix store link that
harness-config replaces whole. omp writes its own YAML config while it runs
(its settings screen, model picker and onboarding all write to it), using a lock
sidecar and an atomic rewrite. Against a read-only store link those writes fail,
and omp breaks on every launch.

harness-config already merges two keys into Claude Code's global config
(`.claude.json`) at activation. When a release stops setting one of those keys,
the old value stays in the file and nothing ever resets it. A merged omp config
has the same problem.

omp can also read Claude Code's folder (its instructions, skills and MCP
servers) when the `claude` source is enabled in omp's settings or
`CLAUDE_CONFIG_DIR` is set. It supports named profiles, each with its own agent
folder.

## Decision

harness-config merges its settings into omp's YAML config at activation instead
of linking a file, because omp's runtime writes need a writable regular file.
This is the only place so far where omp departs from the Claude Code pattern.

The merge follows the existing global-config step. harness-config's keys win on
every activation, so omp matches the declared setup after each switch. Every
other key in the file is kept, which leaves the consumer's own choices and omp's
runtime state alone.

Each merged file has a record of the key paths harness-config set in the last
activation. On the next activation, a key in the record that harness-config no
longer sets is removed from the file before the current values are merged. Only
keys harness-config set are removed, and with no record nothing is removed. The
record applies to Claude Code's global config as well as omp's config, with the
same mechanism and format, because the global config has the same stale-key
problem.

Removing such a key is a minor change. harness-config overwrote that key on
every activation and so owned it. Removing it only lets the harness fall back
to its own default. Pruning files stays major under the versioning ADR, because
it deletes files.

harness-config writes omp's own copies of everything it manages and does not
enable omp's `claude` source. Each harness's folder is then self-contained, and
the two can differ later. Reading Claude Code's folder wouldn't cover everything
anyway: omp ignores its rules and its JSON hooks.

harness-config never installs omp and never checks its version, so the
consumer keeps control of which omp runs, as they do with Claude Code. Unlike
Claude Code, omp gets no minimum-version assertion. omp's config is written even
before omp is installed, so omp starts configured the moment it is.

### Named profiles

Only the default profile's agent folder is managed. Named profiles live in
their own folders and ignore `PI_CODING_AGENT_DIR`. harness-config doesn't write
to them, though omp lets them inherit some files from the default profile, such
as keybindings.

The owner's work and home workflows are the same so far, so one profile covers
them, and managing several would add options and tests nobody uses. Revisit
this when those workflows start to differ and a second profile needs its own
managed setup.

## Consequences

- omp's runtime writes keep working after activation. The cost is an
  activation step that parses YAML and, when the file isn't valid YAML, fails
  and leaves it untouched.
- A consumer can change a managed omp setting at runtime, but the next
  activation sets it back.
- A release can stop managing a setting without leaving its old value behind in
  either harness, and without a major release.
- Disabling a harness skips its activation step, so the keys harness-config
  wrote stay in place until the consumer removes them.
- A capability reaches omp only once harness-config writes omp's copy of it,
  so omp support arrives one capability at a time.
- A consumer who uses named omp profiles gets only what omp inherits from the
  default profile, and configures the rest by hand.
