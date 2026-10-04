# How I work

These apply in every project unless that project's own instructions say
otherwise.

## Working with me

- Do what I asked and nothing more. If you spot something out of scope, tell me
  instead of fixing it.
- Work on the branch I name.
- Don't commit until I've reviewed the changes.

## Coding

- No comments. Name things so the code says what it does. The "why" goes in an
  ADR under `docs/adr/` or in the project's `AGENTS.md`. Directive comments
  that tools read (shebangs, linter pragmas, build tags, SPDX headers) are
  fine.
- Simple over defensive. Validate input once, at the entry point, and trust
  internal code: no guards for states that can't happen.
- Explicit over magic. No reflection, auto-registration, or finding what runs
  by scanning a directory. Wire things directly unless the indirection is easy
  to read.
- Declarative over branching: a lookup table instead of an `if` chain,
  higher-order functions instead of loops. No nested ternaries, and no FP
  libraries.
- One pipeline for every item. Put all items through the same steps (sort,
  then dispatch by type) instead of pulling out subsets to handle separately.
- At most two early returns per function.
- No global or mutable state. Prefer bindings that are never reassigned.
- Pure core, side effects at the edge. Functions return errors as values
  (strings or structured data) and never log them. The outer layer that does
  I/O (handler, route, entry point) decides whether to log, reject or fail.
- Functions over classes, even where classes are idiomatic. Data-only types
  are fine.
- Split a function into named steps once it grows past roughly 40 to 60 lines.
- Follow the codebase's existing naming conventions, then the language's.
- Code is idempotent: running it twice gives the same result as running it
  once.
- Application code is test-driven: write the failing test, run it and watch it
  fail, then write the code. Unit tests for pure code; integration and
  end-to-end tests at I/O and network boundaries.

## Writing

No em-dashes in anything you produce: code, docs, commit messages. Use a comma,
colon, parentheses, or a full stop instead.

## Commits

- Subject format is `<type>(<scope>): <summary>`, for example `add(flake): ...`
  or `update(README): ...`. Types I use: `add`, `update`, `rename`, `bump`.
- No AI attribution trailers (`Co-Authored-By`, "Generated with ...").

## Tooling and installs

My machines are managed declaratively with nix-darwin and home-manager.

- Never install anything globally by hand (`brew install`, `npm i -g`,
  `pip install --user`, `cargo install`). If a tool is missing, tell me which
  one.
- Project tools belong in the project's `flake.nix` devShell, loaded by direnv.
- Python interpreters, venvs and packages are managed by `uv`, not Nix.
