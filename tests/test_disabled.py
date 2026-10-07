import pytest


@pytest.fixture
def seeded_claude_config(in_container):
    """Replaces ~/.claude with entries the harness would prune, and removes it afterwards."""
    in_container(
        "sh",
        "-c",
        "rm -rf /root/.claude"
        " && mkdir -p /root/.claude/rules /root/.claude/hooks /root/.claude/skills/stale"
        " && cd /root/.claude"
        " && touch CLAUDE.md rules/old.md hooks/old.sh skills/stale/SKILL.md",
    )
    yield
    in_container("rm", "-rf", "/root/.claude")


def test_does_nothing_unless_enabled(seeded_claude_config, activate, in_container):
    def listing():
        return in_container("find", "/root/.claude", "-exec", "stat", "-c", "%n %F %Y", "{}", "+").stdout

    before = listing()

    activate("disabled")

    assert listing() == before
