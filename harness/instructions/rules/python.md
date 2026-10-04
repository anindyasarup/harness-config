---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
---

# Python

## Tooling

- Use `uv` for the Python interpreter, environments, dependencies and running
  tools (`uv sync`, `uv add`, `uv run ...`), unless the project already uses
  another package manager.
- Pin the Python version with `uv python pin`, which writes `.python-version`.
- New projects use `pyproject.toml` and `uv.lock`.
- Don't use bare `pip` or `venv`.

## Style

- Prefer a functional style: pure functions, immutability and higher-order
  functions.
- Pass dependencies (logger, db client, clock) into functions as arguments
  instead of importing them. Importing pure functions is fine. For a factory,
  return a closure.
- Model data as immutable values: `@dataclass(frozen=True)`, `NamedTuple`, or
  plain dicts and tuples.
- Don't use `global`.
- Build new values instead of changing existing ones: `a + b` over
  `a.extend(b)`, `a | b` over `a.update(b)`.
- Prefer comprehensions over loops that append and over `map`/`filter` with a
  `lambda`.
- Name the value you mean instead of relying on an implicit default, such as
  taking a dict's first key with `next(iter(d))`.
- Use early returns for cases that end the function.

## Arguments

- Use keyword-only arguments (after `*`) when a function receives dependencies
  or context (`log`, `lookup`, `config`, injected functions), or several values
  with no natural order. Factories always take keyword-only arguments.
- Use positional arguments for small data-in/data-out helpers where the order
  reads naturally: `shift_by(when, duration)`.

## Errors

- Pure code returns problems as data (`errors`, `warnings`) instead of raising.

## Tests

- Use `pytest` unless the project already uses another runner. Put tests in a
  `tests/` directory and run them with `uv run pytest`.
- Write plain test functions, not `unittest.TestCase` classes.
