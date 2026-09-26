# harness-config

Right now I am unable to keep a track of how i've setup claude-code.
The configurations between my work and personal setups are not the same.
I am unable to keep a real track of these configurations and it is becoming
annoying to reign in the drifting configurations.

This repo is meant to be one place that holds how I like to work, my likes
and dislikes, per language conventions etc.

I want to start this out for claude-code to be able expand it for different
models and harnessess.

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
