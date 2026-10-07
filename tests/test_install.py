def test_installs_claude_code(activate, in_container):
    activate("test")

    version = in_container("claude", "--version")
    assert version.returncode == 0, version.stderr
    assert "(Claude Code)" in version.stdout
