# harness-config

Right now I am unable to keep a track of how i've setup claude-code.
The configurations between my work and personal setups are not the same.
I am unable to keep a real track of these configurations and it is becoming
annoying to reign in the drifting configurations.

This repo is meant to be one place that holds how I like to work, my likes
and dislikes, per language conventions etc.

I want to start this out for claude-code to be able expand it for different
models and harnessess.

## Model vs harness vs preferences

This repo splits configuration into three layers, from most to least likely to
change:

1. Model: adjustments for how a particular model behaves, such as prompting
   conventions or known failure modes. These change with the model.
2. Harness: configuration tied to one agent runtime, such as claude-code's
   `settings.json`, hook wiring and file locations. Switching harnesses means
   rewriting this layer.
3. Preferences: the conventions I apply when writing and reviewing code,
   whatever the model or harness. They live in `AGENTS.md` and `rules/` and
   should outlive the other two layers.

Keeping the layers separate means a new model or harness only needs its own
layer written. The preferences stay as they are.

## Constraints

I am building this out for `claude-code >= 2.1.280`. This version of claude-code
reads AGENTS.md natively.

## Configurations

There are three types of configurations that will kickstart my journey.

| Type             | Symlink                                                                 |
| ---------------- | ----------------------------------------------------------------------- |
| settings.json    | No. claude mutates this file.                                           |
| instructions     | Yes. claude only reads these, for ex: `AGENTS.md`, `rules/`, `skills`   |
| states & secrets | No. Also never track these either, for ex: sessions, history, cache etc |

## Retro

While building this repo I realised I could write down my sensible defaults
because I already knew what good looks like from pre-AI era. AI applying these
is not a deterministic action but they're written down now, so I can refer back
to them and build on them.
