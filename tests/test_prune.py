import pytest


@pytest.fixture
def seeded_claude_config(in_container):
    """Replaces ~/.claude with stale entries, a foreign skill link and entries the harness keeps, and removes it afterwards."""
    in_container(
        "sh",
        "-c",
        "rm -rf /root/.claude"
        " && mkdir -p /root/.claude/rules /root/.claude/hooks /root/.claude/skills/stale /root/.claude/skills/synced/kept"
        " && cd /root/.claude"
        " && touch CLAUDE.md rules/old.md hooks/old.sh skills/stale/SKILL.md skills/synced/kept/SKILL.md"
        " && ln -s /tmp skills/foreign"
        " && echo '{}' > settings.json",
    )
    yield
    in_container("rm", "-rf", "/root/.claude")


def test_does_nothing_unless_enabled(seeded_claude_config, activate, in_container):
    def listing():
        return in_container("find", "/root/.claude", "-exec", "stat", "-c", "%n %F %Y", "{}", "+").stdout

    before = listing()

    activate("disabled")

    assert listing() == before


def test_prunes_what_it_replaces(seeded_claude_config, activate, in_container):
    def present(path):
        return in_container("ls", "-d", f"/root/.claude/{path}").returncode == 0

    def read(path):
        return in_container("cat", path).stdout

    def contents(directory):
        return {name: read(f"{directory}/{name}") for name in in_container("ls", directory).stdout.split()}

    activate("test")

    for path in ["skills/stale", "skills/foreign"]:
        assert not present(path), path

    for path in ["CLAUDE.md", "rules", "hooks"]:
        target = in_container("readlink", "-f", f"/root/.claude/{path}")
        assert target.stdout.startswith("/nix/store/"), (path, target.stdout, target.stderr)

    assert read("/root/.claude/CLAUDE.md") == read("/harness-config/preferences/AGENTS.md")
    assert contents("/root/.claude/rules") == contents("/harness-config/preferences/instructions/rules")
    assert in_container("ls", "/root/.claude/hooks").stdout.split() == ["post-tool-use"]
    hook = in_container("readlink", "-f", "/root/.claude/hooks/post-tool-use").stdout.strip()
    assert hook.endswith("/bin/claude-code-post-tool-use"), hook

    assert present("skills/synced/kept/SKILL.md")
    assert in_container("cat", "/root/.claude/settings.json").stdout == "{}\n"


def test_activating_again_after_pruning_changes_nothing(seeded_claude_config, activate, in_container):
    def listing():
        found = in_container(
            "sh",
            "-c",
            "find /root/.claude -printf '%p %y %l\\n' && find /root/.claude -type f -exec sha256sum {} +",
        )
        assert found.returncode == 0, found.stderr
        return sorted(found.stdout.splitlines())

    activate("test")
    before = listing()

    activate("test")

    assert listing() == before
