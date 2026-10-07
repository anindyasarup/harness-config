import json


def test_installs_claude_code(activate, in_container):
    activate("test")

    version = in_container("claude", "--version")
    assert version.returncode == 0, version.stderr
    assert "(Claude Code)" in version.stdout


def test_claude_code_loads_every_linked_skill(activate, in_container):
    activate("test")

    linked = in_container("ls", "/root/.claude/skills").stdout.split()
    session = in_container("claude", "-p", "--output-format", "stream-json", "--verbose", "hi")
    init = json.loads(session.stdout.splitlines()[0])
    loaded = [skill for skill in init["skills"] if skill in linked]

    assert len(loaded) == len(linked), sorted(set(linked) - set(loaded))


def test_claude_code_loads_agents_md_as_claude_md(activate, in_container):
    activate("test")

    context = in_container("claude", "-p", "/context")
    claude_md = in_container("cat", "/root/.claude/CLAUDE.md")
    agents_md = in_container("cat", "/harness-config/preferences/AGENTS.md")

    assert "| User | /root/.claude/CLAUDE.md |" in context.stdout, context.stdout
    assert claude_md.stdout == agents_md.stdout
