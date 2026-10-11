import json


def test_links_the_harness_into_claude_config(activate, in_container):
    activate("test")

    for path in ["CLAUDE.md", "rules", "hooks/post-tool-use", "skills/humanizer"]:
        target = in_container("readlink", "-f", f"/root/.claude/{path}")
        assert target.stdout.startswith("/nix/store/"), (path, target.stdout, target.stderr)

    assert in_container("test", "-f", "/root/.claude/rules/nix.md").returncode == 0
    assert in_container("test", "-x", "/root/.claude/hooks/post-tool-use").returncode == 0


def test_activation_replaces_a_mutated_settings_json(activate, in_container):
    activate("test")
    declared = in_container("cat", "/root/.claude/settings.json").stdout

    in_container("sh", "-c", "rm /root/.claude/settings.json && echo '{\"model\": \"opus\"}' > /root/.claude/settings.json")

    activate("test")

    target = in_container("readlink", "-f", "/root/.claude/settings.json")
    assert target.stdout.startswith("/nix/store/"), (target.stdout, target.stderr)
    assert in_container("cat", "/root/.claude/settings.json").stdout == declared


def test_activation_replaces_a_mutated_keybindings_json(activate, in_container):
    activate("test")

    in_container(
        "sh",
        "-c",
        "rm -f /root/.claude/keybindings.json"
        " && echo '{\"bindings\": [{\"context\": \"Confirmation\", \"bindings\": {\"y\": \"confirm:yes\"}}]}'"
        " > /root/.claude/keybindings.json",
    )

    activate("test")

    target = in_container("readlink", "-f", "/root/.claude/keybindings.json")
    assert target.stdout.startswith("/nix/store/"), (target.stdout, target.stderr)
    assert json.loads(in_container("cat", "/root/.claude/keybindings.json").stdout)["bindings"] == []
