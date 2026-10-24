import json

AUTO_MODE_LISTS = ["environment", "allow", "soft_deny", "hard_deny"]


def settings(activate, in_container):
    activate("test")
    return json.loads(in_container("cat", "/root/.claude/settings.json").stdout)


def test_every_auto_mode_list_keeps_the_built_in_rules(activate, in_container):
    auto_mode = settings(activate, in_container)["autoMode"]

    assert sorted(auto_mode) == sorted(AUTO_MODE_LISTS)
    for name in AUTO_MODE_LISTS:
        assert "$defaults" in auto_mode[name], name


def test_auto_mode_environment_holds_only_the_built_in_rules(activate, in_container):
    assert settings(activate, in_container)["autoMode"]["environment"] == ["$defaults"]


def test_no_rule_is_both_allowed_and_refused_or_asked(activate, in_container):
    configured = settings(activate, in_container)
    permissions = configured["permissions"]
    auto_mode = configured["autoMode"]

    assert permissions["allow"]
    assert permissions["ask"]
    assert set(permissions["allow"]) & set(permissions["deny"]) == set()
    assert set(permissions["allow"]) & set(permissions["ask"]) == set()
    assert set(auto_mode["allow"]) & set(auto_mode["hard_deny"]) == {"$defaults"}
    assert set(auto_mode["allow"]) & set(auto_mode["soft_deny"]) == {"$defaults"}


def test_keeps_the_default_permission_mode(activate, in_container):
    assert settings(activate, in_container)["permissions"]["defaultMode"] == "default"


def test_claude_code_reports_its_rules_on_top_of_the_built_in_ones(activate, in_container, claude):
    activate("with-claude-code")

    auto_mode = json.loads(in_container("cat", "/root/.claude/settings.json").stdout)["autoMode"]
    defaults = json.loads(claude("auto-mode", "defaults").stdout)
    effective = json.loads(claude("auto-mode", "config").stdout)

    for name in AUTO_MODE_LISTS:
        configured = set(auto_mode[name]) - {"$defaults"}
        assert set(effective[name]) == set(defaults[name]) | configured, name
    assert len(effective["allow"]) > len(defaults["allow"])


def test_refuses_activation_lock_file_updates_and_imperative_nix_installs(activate, in_container):
    deny = settings(activate, in_container)["permissions"]["deny"]

    for rule in [
        "Bash(darwin-rebuild switch *)",
        "Bash(home-manager switch *)",
        "Bash(nix flake update *)",
        "Edit(//**/flake.lock)",
        "Bash(nix profile install *)",
        "Bash(nix profile add *)",
        "Bash(nix-env -i *)",
    ]:
        assert rule in deny, rule


def test_asks_before_a_nix_build(activate, in_container):
    assert "Bash(nix build *)" in settings(activate, in_container)["permissions"]["ask"]


def test_refuses_named_installers_and_global_installs_outside_nix(activate, in_container):
    configured = settings(activate, in_container)
    deny = configured["permissions"]["deny"]

    for rule in [
        "Bash(npm *)",
        "Bash(npx *)",
        "Bash(yarn *)",
        "Bash(bun *)",
        "Bash(pnpm -g *)",
        "Bash(pnpm add -g *)",
        "Bash(pnpm install -g *)",
        "Bash(brew install *)",
        "Bash(pip install *)",
        "Bash(python -m pip install *)",
        "Bash(uv tool install *)",
        "Bash(cargo install *)",
        "Bash(go install *)",
        "Bash(corepack enable *)",
        "Bash(rustup *)",
    ]:
        assert rule in deny, rule
    assert "Any global install, except through nix." in configured["autoMode"]["hard_deny"]


def test_manages_project_dependencies_with_pnpm_uv_and_cargo_without_asking(activate, in_container):
    allow = settings(activate, in_container)["permissions"]["allow"]

    for rule in [
        "Bash(pnpm install *)",
        "Bash(pnpm add *)",
        "Bash(pnpm dlx *)",
        "Bash(uv sync *)",
        "Bash(uv add *)",
        "Bash(cargo add *)",
    ]:
        assert rule in allow, rule


def test_refuses_reads_of_secrets_outside_the_repo(activate, in_container):
    configured = settings(activate, in_container)
    deny = configured["permissions"]["deny"]

    for rule in [
        "Read(~/.ssh/**)",
        "Read(~/.gnupg/**)",
        "Read(~/.aws/**)",
        "Read(~/.config/gh/hosts.yml)",
        "Read(~/.netrc)",
    ]:
        assert rule in deny, rule
    assert "Reading `.env` or `.env.*` files outside the repo." in configured["autoMode"]["hard_deny"]


def test_refuses_secrets_in_requests_piped_downloads_exposed_servers_tunnels_scans_logins_and_publishing(activate, in_container):
    configured = settings(activate, in_container)
    deny = configured["permissions"]["deny"]
    hard_deny = configured["autoMode"]["hard_deny"]

    for rule in [
        "Bash(nc -l *)",
        "Bash(ngrok *)",
        "Bash(cloudflared tunnel *)",
        "Bash(tailscale funnel *)",
        "Bash(nmap *)",
        "Bash(nc -z *)",
        "Bash(ssh-copy-id *)",
        "Bash(gh auth login *)",
        "Bash(docker login *)",
        "Bash(pnpm publish *)",
        "Bash(cargo publish *)",
        "Bash(uv publish *)",
        "Bash(gh release create *)",
        "Bash(docker push *)",
    ]:
        assert rule in deny, rule
    for prose in [
        "Sending secrets, tokens or `.env` contents in a request.",
        "Piping a download into a shell or interpreter.",
        "Starting `python -m http.server` without `--bind 127.0.0.1`.",
    ]:
        assert prose in hard_deny, prose


def test_runs_named_tests_builds_lints_and_format_checks_without_asking(activate, in_container):
    allow = settings(activate, in_container)["permissions"]["allow"]

    for rule in [
        "Bash(pnpm test *)",
        "Bash(pnpm typecheck *)",
        "Bash(uv run pytest *)",
        "Bash(cargo clippy *)",
        "Bash(dotnet test *)",
        "Bash(shellcheck *)",
        "Bash(cargo fmt --check *)",
        "Bash(ruff format --check *)",
        "Bash(prek run *)",
        "Bash(just test *)",
        "Bash(just activate *)",
    ]:
        assert rule in allow, rule


def test_no_ask_or_refusal_rule_catches_a_named_build_or_test_command(activate, in_container):
    permissions = settings(activate, in_container)["permissions"]
    prompting = [rule.removeprefix("Bash(").removesuffix(" *)") for rule in permissions["ask"] + permissions["deny"]]

    for command in [
        "pnpm test",
        "pnpm build",
        "pnpm lint",
        "pnpm typecheck",
        "uv run pytest",
        "cargo check",
        "cargo build",
        "cargo test",
        "cargo clippy",
        "dotnet build",
        "dotnet test",
        "shellcheck",
        "cargo fmt --check",
        "dotnet format --verify-no-changes",
        "shfmt -d",
        "prettier --check",
        "ruff format --check",
        "prek run",
        "prek run --files",
        "just test",
        "just up",
        "just down",
        "just build",
        "just activate",
    ]:
        caught = [prefix for prefix in prompting if command == prefix or command.startswith(prefix + " ")]
        assert caught == [], command


def test_asks_before_writing_formats_fixing_running_scripts_and_updating_snapshots(activate, in_container):
    configured = settings(activate, in_container)
    ask = configured["permissions"]["ask"]

    for rule in [
        "Bash(pnpm run *)",
        "Bash(pnpm exec *)",
        "Bash(pnpm format *)",
        "Bash(shfmt -w *)",
        "Bash(prek run --all-files *)",
        "Bash(pnpm lint --fix *)",
        "Bash(cargo clippy --fix *)",
        "Bash(cargo run *)",
        "Bash(pnpm test -u *)",
        "Bash(uv run pytest --snapshot-update *)",
        "Bash(cargo insta accept *)",
        "Bash(just container-start *)",
    ]:
        assert rule in ask, rule
    for prose in [
        "Running a script or recipe through `uv run` or `just` that isn't a named test, build, lint or typecheck command.",
        "Running `cargo fmt`, `dotnet format` or `ruff format` without its check flag, so it rewrites files.",
        "Running any command with `--fix`.",
    ]:
        assert prose in configured["autoMode"]["soft_deny"], prose


def test_refuses_weakening_tests_real_systems_deploys_and_consumer_lock_updates(activate, in_container):
    configured = settings(activate, in_container)
    deny = configured["permissions"]["deny"]

    assert "Bash(prek uninstall *)" in deny
    assert "Bash(just update-consumer *)" in deny
    for prose in [
        "Skipping, deleting or weakening a failing test to make it pass.",
        "Running tests against a real or production system.",
        "Deploying to any environment.",
    ]:
        assert prose in configured["autoMode"]["hard_deny"], prose


def test_asks_before_write_authenticated_and_remote_requests_and_a_local_only_server(activate, in_container):
    configured = settings(activate, in_container)
    ask = configured["permissions"]["ask"]
    soft_deny = configured["autoMode"]["soft_deny"]

    for rule in [
        "Bash(curl -X POST *)",
        "Bash(curl -X PUT *)",
        "Bash(curl -X PATCH *)",
        "Bash(curl -X DELETE *)",
        "Bash(curl -d *)",
        "Bash(curl -F *)",
        "Bash(curl -T *)",
        "Bash(curl -u *)",
        "Bash(gh api -X *)",
        "Bash(gh api -f *)",
        "Bash(gh api -F *)",
        "Bash(gh api --input *)",
        "Bash(python -m http.server --bind 127.0.0.1 *)",
    ]:
        assert rule in ask, rule
    for prose in [
        "Requests with `curl` that send an `Authorization` header.",
        "`ssh`, `scp` or `rsync` to a remote host.",
    ]:
        assert prose in soft_deny, prose


def test_refuses_edits_to_generated_and_system_files_and_damage_outside_the_repo(activate, in_container):
    configured = settings(activate, in_container)
    deny = configured["permissions"]["deny"]

    for rule in [
        "Edit(~/.claude/settings.json)",
        "Edit(~/.zshrc)",
        "Edit(~/.config/**)",
        "Edit(//etc/**)",
        "Edit(//nix/store/**)",
        "Edit(//Library/**)",
        "Edit(//System/**)",
        "Edit(~/.ssh/**)",
        "Bash(sudo *)",
    ]:
        assert rule in deny, rule
    for prose in [
        "Removing files outside the repo with `rm` or `rm -rf`.",
        "Changing permissions or ownership outside the repo with `chmod` or `chown`.",
    ]:
        assert prose in configured["autoMode"]["hard_deny"], prose


def test_asks_before_reading_or_changing_files_outside_the_repo(activate, in_container):
    configured = settings(activate, in_container)

    assert "Read(//nix/store/**)" in configured["permissions"]["ask"]
    for prose in [
        "Reading or listing files outside the repo, including with `ls`, `cat`, `head`, `tail`, `rg`, `fd` or `find`.",
        "Editing or writing files outside the repo.",
        "Copying, moving or creating files or folders outside the repo with `cp`, `mv`, `mkdir` or `touch`.",
    ]:
        assert prose in configured["autoMode"]["soft_deny"], prose


def test_writes_temporary_files_without_asking(activate, in_container):
    configured = settings(activate, in_container)

    assert "Edit(//tmp/**)" in configured["permissions"]["allow"]
    assert "Writing files in the job's temporary folder, `$CLAUDE_JOB_DIR/tmp`." in configured["autoMode"]["allow"]


def test_runs_lookups_and_read_only_requests_without_asking(activate, in_container):
    configured = settings(activate, in_container)
    allow = configured["permissions"]["allow"]
    auto_allow = configured["autoMode"]["allow"]

    for rule in ["Bash(dig *)", "Bash(nslookup *)", "Bash(host *)", "Bash(ping -c *)"]:
        assert rule in allow, rule
    for prose in [
        "Searching the web with WebSearch and fetching pages with WebFetch.",
        "GET requests with `curl` or `wget` that send no credentials.",
        "Requests with `curl` to `localhost` or `127.0.0.1`, on any port or path.",
        "GET requests with `gh api`.",
    ]:
        assert prose in auto_allow, prose
