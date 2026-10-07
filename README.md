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
| claude-code     | in-progress |
| pi-coding-agent | planned     |
| omp             | planned     |

I am building this out for `claude-code >= 2.1.280`. This version of claude-code
reads `AGENTS.md` natively.

## Configurations

There are three types of configuration that will kickstart my journey.

| Type             | Symlink                                                               |
| ---------------- | --------------------------------------------------------------------- |
| settings.json    | No. claude mutates this file.                                         |
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
