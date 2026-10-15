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
   whatever the harness. They live in `AGENTS.md` and `rules/` and should
   outlive the harness layer.

Keeping the layers separate allows to build for a new harness,
and the preferences carry over untouched.

## Constraints

For the time being, this only supports claude-code.

| Harness         | Status      |
| --------------- | ----------- |
| claude-code     | completed   |
| pi-coding-agent | planned     |
| omp             | planned     |

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
