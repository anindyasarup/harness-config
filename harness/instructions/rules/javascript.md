---
paths:
  - "**/*.{js,mjs,cjs,jsx,ts,mts,cts,tsx}"
---

# JavaScript / TypeScript

## Style

- Prefer a functional style: pure functions, immutability, and higher-order
  functions. Avoid mutation.
- Use `const` over `let`.
- Use `const` arrow functions only. No `function` declarations, no classes.
- Pass dependencies (logger, db client, clock) into functions as arguments
  instead of importing them. Importing pure functions is fine.
- Merge arrays with `.concat()`, not spread: `a.concat(b)` not `[...a, ...b]`.

## Naming

- Use `kebab-case` for file names.
- Use `camelCase` for variables and functions.
- Prefix a function that still takes its dependencies with `_`, one `_` per
  step left to apply. Each application drops one `_`, and the wired-up function
  has none:

  ```js
  const _log = (logger) => (input) => logger.info(input);
  const log = _log(logger);
  log("hello");
  ```

## Tests

- Use the `node:test` runner unless the project already uses another. Use `it`,
  not `test`.
- Tests may mutate shared fixtures in hooks, for example emptying a queue with
  `queue.length = 0` in `afterEach`.
