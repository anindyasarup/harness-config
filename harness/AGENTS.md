# How I work

These apply in every project unless that project's own instructions say
otherwise.

## Working with me

- Do what I asked and nothing more. If you spot something out of scope, tell me
  instead of fixing it.
- If a request can be read more than one way, list the readings and ask. Don't
  pick one silently.
- Say so if there's a simpler approach than the one I asked for.
- Don't reformat, rename or tidy code next to your change. Every changed line
  should come from the request.
- Remove imports, variables and functions that your own change made unused.
  Leave dead code that was already there, and mention it.
- Work on the branch I name.
- Don't commit until I've reviewed the changes.

## Coding

- No comments. Name things so the code says what it does. The "why" goes in an
  ADR under `docs/adr/` or in the project's `AGENTS.md`. Directive comments
  that tools read (shebangs, linter pragmas, build tags, SPDX headers) are
  fine.
- Simple over defensive. Validate input once, at the entry point, and trust
  internal code: no guards for states that can't happen.
- No abstraction for code used once.
- No options or configurability I didn't ask for.
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

## Testing

### When

- Application code is test-driven: write the failing test, run it and watch it
  fail, then write the code.
- For work that isn't test-driven, name how you'll verify it (a build, a script
  run) before starting, and run that check before saying it's done.
- If a requirement could go in a comment, write a test for it instead.

### Which tier

- Choose the tier that proves the behaviour, even when a cheaper tier would be
  quicker to write.
- Unit tests: pure logic and its edge cases (empty results, missing config,
  malformed data the code reports as errors). Feed in known inputs; no real I/O.
- Integration tests: any code that crosses a boundary (database, HTTP,
  filesystem, queue), including bad input rejected at the entry point, such as a
  malformed API request.
- E2E tests: critical paths, wiring between producers and consumers, and bad
  input that arrives through another service. Unit tests build their fixtures by
  hand, so shape mismatches between a producer and its consumers only show up
  here.

### How

- Test through the public interface. Don't assert on implementation details.
- Set up each test on its own, with no global or shared mutable state in the
  test file. Shared fixtures are fine if a hook resets them between tests.
- Keep tests deterministic and offline; local containers are fine. Inject the
  network, clock and randomness when a test needs them.
- Never let a test touch a real or production system, even read-only.
- Don't test third-party libraries or trivial getters.

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
