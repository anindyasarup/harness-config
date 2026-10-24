# build and test runners

## Don't ask

- `pnpm test`, `pnpm build`, `pnpm lint`, `pnpm typecheck`
- `uv run pytest`
- `cargo check`, `cargo build`, `cargo test`, `cargo clippy`
- `dotnet build`, `dotnet test`
- `shellcheck`
- `cargo fmt --check`, `dotnet format --verify-no-changes`, `shfmt -d`,
  `prettier --check`, `ruff format --check`
- `prek run`, `prek run --files`
- `just test`, `just up`, `just down`, `just build`, `just activate`

## Ask

- `pnpm run`, `pnpm exec`, `uv run`, `just` with anything else
- `pnpm format`, `cargo fmt`, `dotnet format`, `shfmt -w`, `ruff format`
- `--fix`, `prek run --all-files`
- `pnpm dev`, `cargo run`, `dotnet run`
- `pnpm test -u`, `pytest --snapshot-update`, `cargo insta accept`
- `just container-start`, `just container-stop`

## Never do

- Skip, delete or weaken a failing test to make it pass
- Run tests against a real or production system
- Deploy to any environment
- `prek uninstall`
- `just update-consumer`
