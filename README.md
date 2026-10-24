# harness-config

Right now I am unable to keep track of how I've set up claude-code. My work
and personal setups are not configured the same way, and it is becoming
annoying to rein in the drifting configurations.

This repo is meant to be one place that holds how I like to work, my likes
and dislikes, per-language conventions, etc.

I want to start this out with claude-code and be able to expand it to
different harnesses.

## Harness vs preferences

This repo splits configuration into two layers:

1. Harness: configuration tied to one agent runtime, such as claude-code's
   `settings.json`, hook wiring and file locations. Switching harnesses means
   rewriting this layer.
2. Preferences: the conventions I apply when writing and reviewing code,
   whatever the harness. They live in `AGENTS.md`, `rules/` and the
   permissions rules in `permissions/`, and should outlive the harness layer.

Keeping the layers separate allows to build for a new harness,
and the preferences carry over untouched.

## Constraints

For the time being, this only supports claude-code.

| Harness         | Status      |
| --------------- | ----------- |
| claude-code     | completed   |
| pi-coding-agent | dropped     |
| omp             | in-progress |

I am building this out for `claude-code >= 2.1.280`. This version of claude-code
reads `AGENTS.md` natively.

It needs home-manager unstable for `programs.claude-code.mutableSettings`.

## Setup

**WARNING: Read what it replaces first.** Once on, this owns most of the
claude-code config directory.

| Heads up      | Details                                                                                    |
| ------------- | ------------------------------------------------------------------------------------------ |
| Harnesses     | Never installed from here. I install claude-code myself.                                   |
| Replaced      | `settings.json`, `keybindings.json`, `CLAUDE.md`, `rules/`, `hooks/`                       |
| Deleted       | Skills it doesn't declare except `skills/synced`, `agents/`, `commands/`, `output-styles/` |
| Merged        | `.claude.json`: sets the keys from `claude-code/global-config.nix`, keeps the rest         |
| Removed       | `.claude.json` keys a release stops setting, listed in `.claude.json.managed-keys.json`    |
| Settings      | `programs.claude-code.mutableSettings` has to stay `false`                                 |
| Version check | Only runs when claude-code comes from `programs.claude-code.package`, warns otherwise      |
| MCP servers   | Not managed. I add them with `claude mcp add`, and claude-code keeps them                  |

Add it as an input to the flake that builds my machines. It has no `nixpkgs`
input, so there's nothing to `follows`:

```nix
inputs.harness-config.url = "github:anindyasarup/harness-config";
```

The default skills come from two third-party inputs, `humanizer` and
`mattpocock-skills`, at the revisions in this repo's `flake.lock`. To pin or
swap either one without forking, I override it in the flake that builds my
machines:

```nix
inputs.harness-config.inputs.humanizer.url = "github:blader/humanizer/<rev>";
```

Hand the module to home-manager. Where it goes depends on how home-manager is
integrated:

| Host                    | Where the module goes                                   |
| ----------------------- | ------------------------------------------------------- |
| standalone home-manager | `homeManagerConfiguration { modules = [ ... ]; }`       |
| nix-darwin              | `harness-config.darwinModules.default` in the system    |
| NixOS                   | `harness-config.nixosModules.default` in the system     |

`tests/consumer/flake.nix` is the reference for all three.

On nix-darwin and NixOS, the system module adds
`harness-config.homeModules.default` to `home-manager.sharedModules`. That
option comes from home-manager's own system module, so import both:

```nix
darwinConfigurations.personal = nix-darwin.lib.darwinSystem {
  modules = [
    home-manager.darwinModules.home-manager
    harness-config.darwinModules.default
  ];
};
```

NixOS uses `nixpkgs.lib.nixosSystem` with
`home-manager.nixosModules.home-manager` and
`harness-config.nixosModules.default`.

Then turn on claude-code in a home module, and install it if I haven't
already. If claude-code is also in `home.packages`, I take it out of there, or
two copies get installed:

```nix
{ pkgs, ... }:
{
  harness.claude-code.enable = true;
  programs.claude-code.package = pkgs.claude-code;
}
```

claude-code is unfree, so the nixpkgs that home-manager uses has to allow it:

```nix
nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "claude-code";
```

It sets up `~/.claude`. If claude-code's config lives somewhere else, I set
`programs.claude-code.configDir` to that path.

Rebuild, and claude-code picks it up on its next start.

### Managed keys in `.claude.json`

Next to `.claude.json`, activation writes `.claude.json.managed-keys.json`, a
JSON list of the key paths it set, such as `[["defaultToAgentsView"]]`. On the
next activation, any key in that list that harness-config no longer sets is
removed from `.claude.json`, so claude-code falls back to its own default. Keys
I set myself are never removed, and the first activation, with no record yet,
removes nothing.

Turning off `harness.claude-code.enable` skips this step, so the managed keys
stay in `.claude.json`. To clear them, I remove each path listed in the record
and then the record itself:

```sh
jq --slurpfile keys ~/.claude.json.managed-keys.json 'delpaths($keys[0])' \
  ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
rm ~/.claude.json.managed-keys.json
```

If `CLAUDE_CONFIG_DIR` is set, both files live there instead of in `~`.

### omp

omp support is in progress. Turning it on merges the settings from
`omp/settings.nix` into omp's `config.yml`: omp thinks at `medium` effort and
asks before acting (`always-ask`), like claude-code. It has its own switch, so
it works with or without claude-code:

```nix
{ pkgs, ... }:
{
  harness.omp.enable = true;
  home.packages = [ pkgs.omp ];
}
```

Like claude-code, omp is never installed from here.

omp gets the same instructions as claude-code: `harness.omp.instructions`
(default `preferences/AGENTS.md`) is linked as `AGENTS.md` in omp's agent
folder, replacing any file already there. omp only reads it, so a read-only
link is enough.

omp gets the same skills too: each one in `harness.omp.skills` (default the
same skills as claude-code) is linked as `skills/<name>` in omp's agent folder.
Activation deletes every other entry in `skills/`, including skills I added by
hand. Those can live in `~/.agents/skills` instead: omp reads it too, and
harness-config leaves it alone.
Pinning or swapping `humanizer` or `mattpocock-skills` changes both harnesses.
omp skips, without a warning, any skill whose `SKILL.md` has no `description`
in its frontmatter. Every default skill has one; `omp skill list` shows what omp
loaded.

omp gets the same rules too. `harness.omp.rules` (default
`preferences/instructions/rules`) is linked as `rules/` in omp's agent folder,
and activation first deletes any `rules/` already there, including rules I
wrote by hand. omp ignores `paths:`, so the build turns each rule's `paths:`
into a scope on omp's edit and write tools. In a session, omp loads a rule the
first time it edits or writes a matching file; claude-code also loads it when it
reads one. As with claude-code, a rule without `paths:` fails the build.
`omp ttsr list` shows which rules omp loaded.

omp gets the same keybindings too. harness-config doesn't remap any key in
claude-code, so `keybindings.yml` in omp's agent folder is linked as an empty
mapping, replacing any file already there, and both harnesses keep their own
default keys. Since nothing is remapped, no key is missing from omp.
Translating claude-code's actions to omp's will come with the first remapped
key. omp only rewrites this file to migrate old action names, and the empty
mapping has none, so a read-only link is enough.

omp gets the same post-tool-use checks too. `harness.omp.hooks.postToolUse`
(default `no-comments` and `no-emdash`, as in claude-code) runs on the text omp
adds with its write and edit tools, whichever edit mode omp is in. `hooks/` in
omp's agent folder is linked to a TypeScript hook that passes that text to
claude-code's check runner. Activation first deletes any `hooks/` already
there, including hooks I wrote by hand. When a check fails, the tool result
becomes an error with the check's reason added, and the model reads it there.
As with claude-code, an unknown check name fails the build.

omp refuses, asks about and allows the same commands as claude-code. Each
command in the permissions rules becomes two of omp's `bash.patterns`, the bare
command and the command followed by `*`, ordered deny, then prompt, then allow,
because omp uses the first pattern that matches. Denying the `sh`, `bash` and
`zsh` segments refuses piping a download into a shell, and
`tools.approval.eval` makes shells started from omp's eval tool ask first. omp
has no path or prose rules, so edit and prose rules don't reach it. Never do
read rules reach it through the read guard below.
`omp config get bash.patterns` shows the patterns omp uses.

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
glob tools aren't checked. Activation replaces only
`extensions/harness-read-guard.ts` and leaves the rest of `extensions/` alone.

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

As with claude-code, activation also deletes `agents/` and `commands/`, and
keeps everything else in the agent folder, such as `mcp.json`, the rest of
`extensions/` and sessions.

omp's agent folder is `~/.omp/agent`. If it lives somewhere else, I set
`home.sessionVariables.PI_CODING_AGENT_DIR` to that path.

**WARNING:** plain pi reads `PI_CODING_AGENT_DIR` too, and home-manager's
`programs.pi-coding-agent.configDir` can set it. If it points at pi's folder,
omp and harness-config both write there.

omp rewrites `config.yml` while it runs, so it stays a regular file instead of
a link. Each activation sets the managed keys again, keeps everything else
(such as my theme or onboarding answers), and creates the file if it's
missing. If `config.yml` isn't valid YAML, or its root isn't a mapping,
activation fails and leaves the file alone. omp's onboarding wizard still runs
on first launch.

Activation lists the key paths it set in `config.yml.managed-keys.json`, as it
does for `.claude.json`. When a release stops setting a key, the next
activation removes it and omp falls back to its own default. Turning off
`harness.omp.enable` skips this step and leaves both files alone. To clear the
managed keys, I remove each
path listed in the record with yq (`yq-go`) and then the record itself:

```sh
yq -i "delpaths($(cat ~/.omp/agent/config.yml.managed-keys.json))" \
  ~/.omp/agent/config.yml
rm ~/.omp/agent/config.yml.managed-keys.json
```

If `PI_CODING_AGENT_DIR` is set, both files live there instead.

These claude-code settings have no omp equivalent, so omp doesn't get them:
fullscreen TUI (`tui`), auto-scroll (`autoScrollEnabled`), commit and PR
attribution (`attribution`) and agents view at startup (`defaultToAgentsView`).

## Configurations

There are three types of configuration that will kickstart my journey.

| Type             | Symlink                                                               |
| ---------------- | --------------------------------------------------------------------- |
| settings.json    | Yes. Built from `claude-code/settings.nix`, claude can't mutate it    |
| .claude.json     | No. Sets keys from `claude-code/global-config.nix`, keeps the rest    |
| instructions     | Yes. claude only reads these, for ex: `AGENTS.md`, `rules/`, `skills` |
| states & secrets | No. Never track these either, for ex: sessions, history, cache etc    |

## Testing

I test this flake end to end with the help of Apple containers. pytest starts
one throwaway `nixos/nix` container, where a separate test flake adds this flake
as an input. Each test builds one of that flake's home-manager configurations
inside the container, activates it, and checks that everything in `~/.claude` is
built the way it is supposed to be.

## Retro

While building this repo I realised I could write down my sensible defaults
because I already knew what good looks like from the pre-AI era. AI doesn't
apply them deterministically, but they're written down now, so I can refer back
to them and build on them.
