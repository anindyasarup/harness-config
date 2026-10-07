def test_links_the_harness_into_claude_config(activate, in_container):
    activate("test")

    for path in ["CLAUDE.md", "rules", "hooks/post-tool-use", "skills/humanizer"]:
        target = in_container("readlink", "-f", f"/root/.claude/{path}")
        assert target.stdout.startswith("/nix/store/"), (path, target.stdout, target.stderr)

    assert in_container("test", "-f", "/root/.claude/rules/nix.md").returncode == 0
    assert in_container("test", "-x", "/root/.claude/hooks/post-tool-use").returncode == 0
