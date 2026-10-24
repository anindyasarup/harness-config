# harness-config

harness-config holds how the owner likes coding agents to work and applies it
to each harness from one flake input.

## Auto mode

**Command group**:
The permission rules for one area of work, such as git, nix, installs, files
outside the repo, network, or build and test runners.
*Avoid*: Category, rule set

**Don't ask**:
The verdict for a command the agent runs without asking.
*Avoid*: Allow, whitelist

**Ask**:
The verdict for a command the agent runs only after the owner approves it.
*Avoid*: Soft deny, prompt

**Never do**:
The verdict for a command the agent never runs; it hands the command to the
owner instead.
*Avoid*: Deny, hard deny, blacklist
