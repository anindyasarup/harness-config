# Preferences

Each preference lives once in the preferences layer, and each harness gets its
own copy of it, written in that harness's format. [Ownership](ownership.md)
lists what activation replaces or deletes in each harness's folder.

| Preference                    | claude-code                      | omp                                    |
| ----------------------------- | -------------------------------- | -------------------------------------- |
| [Instructions](#instructions) | `CLAUDE.md`                      | `AGENTS.md`                            |
| [Skills](#skills)             | `skills/<name>`                  | `skills/<name>`                        |
| [Rules](#rules)               | `rules/`                         | `rules/`, loaded on edit and write     |
| [Hooks](#hooks)               | `hooks/`                         | `hooks/`, a TypeScript hook            |
| [Permissions](#permissions)   | `permissions` and `autoMode`     | `bash.patterns` and a read guard       |
| [Keybindings](#keybindings)   | `keybindings.json`               | `keybindings.yml`                      |
| [Settings](#settings)         | `settings.json`, `.claude.json`  | `config.yml`, merged                   |

## Instructions

`harness.claude-code.instructions` and `harness.omp.instructions` default to
`preferences/AGENTS.md`.

- claude-code: linked as `CLAUDE.md` in the config folder.
- omp: linked as `AGENTS.md` in omp's agent folder, replacing any file already
  there. omp only reads it, so a read-only link is enough.

## Skills

The default skills come from two third-party inputs, `humanizer` and
`mattpocock-skills`, at the revisions in this repo's `flake.lock`. To pin or
swap either one without forking, I override it in the flake that builds my
machines, and the change reaches both harnesses:

```nix
inputs.harness-config.inputs.humanizer.url = "github:blader/humanizer/<rev>";
```

- claude-code: every skill in `harness.claude-code.skills` is linked as
  `skills/<name>`.
- omp: every skill in `harness.omp.skills` (by default the same skills as
  claude-code) is linked as `skills/<name>` in omp's agent folder. omp skips,
  without a warning, any skill whose `SKILL.md` has no `description` in its
  frontmatter. Every default skill has one, and `omp skill list` shows what
  omp loaded.

## Rules

`harness.claude-code.rules` and `harness.omp.rules` default to
`preferences/instructions/rules`, linked as `rules/`. A rule without `paths:`
fails the build.

- claude-code: loads a rule when it reads, edits or writes a file its `paths:`
  match.
- omp: ignores `paths:`, so the build turns each rule's `paths:` into a scope
  on omp's edit and write tools. In a session, omp loads a rule the first time
  it edits or writes a matching file. `omp ttsr list` shows which rules omp
  loaded.

## Hooks

`harness.claude-code.hooks.postToolUse` and `harness.omp.hooks.postToolUse`
default to `no-comments` and `no-emdash`. An unknown check name fails the
build.

- claude-code: the checks run on the text claude-code adds with Write, Edit,
  MultiEdit or NotebookEdit.
- omp: the checks run on the text omp adds with its write and edit tools,
  whichever edit mode omp is in. `hooks/` in omp's agent folder is linked to a
  TypeScript hook that passes that text to claude-code's check runner. When a
  check fails, the tool result becomes an error with the check's reason added,
  so the model reads the reason in that error.

## Permissions

Both harnesses read the same rule set in `preferences/permissions`, and each
gets it in its own syntax. [ADR 0003](adr/0003-shared-rule-set.md) has the
mapping.

- claude-code: rendered as `permissions` and `autoMode` in `settings.json`.
- omp: refuses, asks about and allows the same commands as claude-code. Each
  command in the permissions rules becomes two of omp's `bash.patterns`, the
  bare command and the command followed by `*`, ordered deny, then prompt, then
  allow, because omp uses the first pattern that matches. Denying the `sh`,
  `bash` and `zsh` segments refuses piping a download into a shell, and
  `tools.approval.eval` makes shells started from omp's eval tool ask first.
  omp has no path or prose rules, so edit and prose rules don't reach it. Never
  do read rules reach it through the read guard below.
  `omp config get bash.patterns` shows the patterns omp uses.

### omp read guard

`extensions/harness-read-guard.ts` in omp's agent folder is linked to an
extension that stops omp reading secrets. It blocks a call to omp's read tool
or a shell command when the call names a Never do read path from the
permissions rules (`~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.config/gh/hosts.yml` and
`~/.netrc`), or a `.env` or `.env.*` file outside the git repo omp runs in.
Outside a repo, the working folder counts as the repo. The blocked call
returns the reason as an error, so the model sees it. Reads of other files
outside the repo still work.

The guard has gaps. It checks each word of a shell command after expanding
`~`, `$HOME` and `${HOME}`, so a command that reaches a secret through a
relative path, such as `cd ~ && cat .ssh/id_rsa`, still runs. omp's grep and
glob tools aren't checked.

## Keybindings

harness-config doesn't remap any key in claude-code, so omp has nothing to
copy and both harnesses keep their own default keys.

- claude-code: `keybindings.json` is built from `claude-code/keybindings.nix`.
- omp: `keybindings.yml` in omp's agent folder is linked as an empty mapping,
  replacing any file already there. Translating claude-code's actions to
  omp's will come with the first remapped key. omp only rewrites this file to
  migrate old action names, and the empty mapping has none, so a read-only
  link is enough.

## Settings

- claude-code: `settings.json` is built from `claude-code/settings.nix`, and
  the keys from `claude-code/global-config.nix` are merged into
  `.claude.json`.
- omp: the settings from `omp/settings.nix` are merged into omp's
  `config.yml`: omp thinks at `medium` effort and asks before acting
  (`always-ask`), like claude-code.

### omp model

omp gets no default model from here. To use a provider subscription such as
GitHub Copilot, I set `harness.omp.model` to the provider and one of its
models. Activation writes them to omp's `modelRoles.default` as
`provider/model`:

```nix
harness.omp.model = {
  provider = "github-copilot";
  model = "claude-sonnet-4.5";
};
```

claude-code's model doesn't change. If I leave the option unset, activation
leaves omp's model alone and removes a model it set earlier. I still log in to
the provider myself, with `omp login github-copilot` or `/login` inside omp.

### Not carried over to omp

These claude-code settings have no omp equivalent, so omp doesn't get them:
fullscreen TUI (`tui`), auto-scroll (`autoScrollEnabled`), commit and PR
attribution (`attribution`) and agents view at startup (`defaultToAgentsView`).
