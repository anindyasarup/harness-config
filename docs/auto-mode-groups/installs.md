# installs

## Don't ask

- `pnpm install`, `pnpm install --frozen-lockfile`
- `pnpm add`, `pnpm remove`, `pnpm update`
- `pnpm dlx`
- `uv sync`, `uv add`, `uv remove`
- `cargo add`, `cargo remove`

## Never do

- Any global install, except through nix
- `npm`, `npx`, `yarn`, `bun`
- `pnpm -g`
- `brew install`, `brew tap`, `mas install`, `port install`
- `pip install`, `pip3 install`, `python -m pip install`, `pip install --user`
- `pipx install`, `uv tool install`, `uv pip install --system`
- `cargo install`, `cargo binstall`, `go install`, `gem install`
- `deno -g`, `dotnet -g`, `composer global`
- `mise -g`, `asdf install`, `volta install`, `corepack enable`
- `rustup`
- `curl ... | sh`
