import json

CONSUMER = ["--no-write-lock-file", "--override-input", "harness-config", "path:/harness-config"]


def test_nixos_module_links_the_harness_into_a_users_home(in_container):
    built = in_container(
        "nix",
        "build",
        "--no-link",
        "--print-out-paths",
        *CONSUMER,
        "/consumer#nixosConfigurations.harness.config.home-manager.users.alice.home-files",
    )

    assert built.returncode == 0, built.stderr
    assert in_container("test", "-e", f"{built.stdout.strip()}/.claude/CLAUDE.md").returncode == 0


def test_darwin_module_declares_the_harness_in_a_users_home(in_container):
    evaluated = in_container(
        "nix",
        "eval",
        "--json",
        *CONSUMER,
        "/consumer#darwinConfigurations.harness.config.home-manager.users.alice.home.file",
        "--apply",
        "files: map (file: file.target) (builtins.attrValues files)",
    )

    assert evaluated.returncode == 0, evaluated.stderr
    assert ".claude/CLAUDE.md" in json.loads(evaluated.stdout)
