let
  commands =
    verdict:
    map (command: {
      inherit verdict command;
    });
  prose =
    verdict:
    map (prose: {
      inherit verdict prose;
    });
in
commands "dont-ask" [
  "pnpm test"
  "pnpm build"
  "pnpm lint"
  "pnpm typecheck"
  "uv run pytest"
  "cargo check"
  "cargo build"
  "cargo test"
  "cargo clippy"
  "dotnet build"
  "dotnet test"
  "shellcheck"
  "cargo fmt --check"
  "dotnet format --verify-no-changes"
  "shfmt -d"
  "prettier --check"
  "ruff format --check"
  "prek run"
  "prek run --files"
  "just test"
  "just up"
  "just down"
  "just build"
  "just activate"
]
++ commands "ask" [
  "pnpm run"
  "pnpm exec"
  "pnpm format"
  "shfmt -w"
  "pnpm lint --fix"
  "cargo clippy --fix"
  "prek run --all-files"
  "pnpm dev"
  "cargo run"
  "dotnet run"
  "pnpm test -u"
  "pytest --snapshot-update"
  "uv run pytest --snapshot-update"
  "cargo insta accept"
  "just container-start"
  "just container-stop"
]
++ prose "ask" [
  "Running a script or recipe through `uv run` or `just` that isn't a named test, build, lint or typecheck command."
  "Running `cargo fmt`, `dotnet format` or `ruff format` without its check flag, so it rewrites files."
  "Running any command with `--fix`."
]
++ prose "never-do" [
  "Skipping, deleting or weakening a failing test to make it pass."
  "Running tests against a real or production system."
  "Deploying to any environment."
]
++ commands "never-do" [
  "prek uninstall"
  "just update-consumer"
]
