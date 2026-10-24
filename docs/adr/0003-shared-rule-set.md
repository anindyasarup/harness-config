# 3. One rule set, rendered per harness

## Context

The owner wants Claude Code to run in auto mode, where a classifier approves
most actions without a prompt. Auto mode on its own approves too much: it would
push, install tools globally, run `home-manager switch`, publish packages and
read secrets outside the repo. omp has no classifier and approves everything
unless told otherwise.

The owner's rules are written as six Command groups (git, nix, installs, files
outside the repo, network, build and test runners). Each line in a group has a
verdict: Don't ask, Ask or Never do. Until now the groups were only documents,
so nothing enforced them and a consumer got none of them.

Claude Code has two mechanisms for these rules. Permission rules
(`permissions.allow`, `ask` and `deny`) match tool calls by pattern. Ask and
deny rules run before the classifier, so they still prompt or block in auto
mode, and deny blocks in every mode. The `autoMode` lists (`environment`,
`allow`, `soft_deny` and `hard_deny`) hold prose that the classifier reads.
`hard_deny` beats `allow`, and `allow` beats `soft_deny`. `autoMode` is read
only from user settings, managed settings or the command line, never from
project settings.

Each `autoMode` list comes with built-in entries from Anthropic. The string
`"$defaults"` splices them in; a list without it replaces them. A single
built-in entry can't be removed. Two built-in `allow` entries disagree with the
owner's rules: Git Push Destination treats pushing to the session's repo as
ordinary, and Toolchain Bootstrap approves the official one-line toolchain
installers.

## Decision

### One rule set, a renderer per harness

The Command groups live once, as a harness-neutral rule set in the preferences
layer, one file per group. The group files are imported by name, with no folder
scan. Each entry has a verdict and exactly one kind: a command, a read path, an
edit path or a prose rule. Commands are plain command text with no harness
syntax. A rule that depends on context, such as "outside the repo" or "a GET
request", is a prose rule, because a pattern for it would match the wrong
commands.

A permissions library holds a renderer per harness, in a table keyed by harness.
Every entry goes through the same pipeline: sort by verdict, then dispatch by
kind. Only the renderers know a harness's syntax, so Claude Code and omp read
every rule from one source, and a new harness needs only a new renderer.

The rules are an opinion like the rest of harness-config's settings. There is
no option to turn them off, and changing them is a minor release under the
versioning ADR. The settings file is a read-only generated file replaced on
every activation, so the agent can't loosen its own rules.

### Claude Code mapping

| Kind      | Don't ask           | Ask                   | Never do              |
| --------- | ------------------- | --------------------- | --------------------- |
| Command   | `permissions.allow` | `permissions.ask`     | `permissions.deny`    |
| Read path | `Read` in `allow`   | `Read` in `ask`       | `Read` in `deny`      |
| Edit path | `Edit` in `allow`   | `Edit` in `ask`       | `Edit` in `deny`      |
| Prose     | `autoMode.allow`    | `autoMode.soft_deny`  | `autoMode.hard_deny`  |

A command becomes a prefix rule. Claude Code's `Write` path rules never match,
so write rules are expressed as `Edit` rules. The job's temporary folder has a
different path in every job, so writes to it are a prose rule.

Every `autoMode` list, `environment` included, contains `"$defaults"`.
`environment` has no other entries.

### Keeping the built-in rules

Keeping `"$defaults"` gives the owner Anthropic's protections and their future
fixes. Replacing a list would mean copying the built-in entries and keeping the
copy up to date by hand.

The two built-in entries that disagree are both in `allow`, and the owner's
rules override each of them without removing it. `git push` is an Ask command,
and ask rules run before the classifier, so a push prompts whatever Git Push
Destination says. "Any global install, except through nix" is a Never do prose
rule in `hard_deny`, which beats `allow`, so the classifier refuses what
Toolchain Bootstrap would approve. The named installers (`rustup`,
`brew install` and the rest) are also Never do commands, which block before the
classifier runs.

### Nix is exempt from the global install rule

The owner's machines are managed declaratively with nix-darwin and home-manager,
and every project has a `flake.nix` devShell. Adding a package there is how a
tool is meant to reach the machine, and it lands only when the owner activates.
Without the exemption the classifier could refuse adding a package to the nix
source as a global install. The exemption doesn't cover imperative nix installs:
`nix profile install`, `nix profile add` and `nix-env -i` are Never do commands
in the nix group.

### Publishing and deploying are Never do

Publishing a package, creating a release, pushing an image and deploying to any
environment change something public or live as the owner. Most can't be taken
back: a registry keeps a published version, and users may already have pulled
it. No step of the agent's work needs them, so they are Never do and the agent
hands the command to the owner. Deploying covers every environment, because a
command line rarely shows whether its target is staging or production.

## Consequences

- Each rule is written once, and a harness can express only what its renderer
  supports. omp renders commands as shell approval patterns and drops read,
  edit and prose entries; a read guard extension covers the Never do read
  paths.
- A Never do command is refused in every permission mode, so the rules still
  hold if the owner leaves auto mode.
- An Ask prose rule is weaker than an Ask command. The classifier decides
  whether it matches, and an `allow` entry, built-in or not, overrides it.
- Prefix rules can't see `git -C dir push`, `git -c key=value` or pipes. The
  classifier handles those forms.
- A project's settings can add allow rules, which widen Don't ask in that repo.
  They can't override Never do, because deny rules block in every mode and
  project settings can't change `autoMode`. The gap is accepted, because
  closing it needs managed settings, which home-manager doesn't own.
