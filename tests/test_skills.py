import json


def test_claude_code_loads_every_linked_skill(activate, in_container):
    activate("test")

    linked = in_container("ls", "/root/.claude/skills").stdout.split()
    session = in_container("claude", "-p", "--output-format", "stream-json", "--verbose", "hi")
    init = json.loads(session.stdout.splitlines()[0])
    loaded = [skill for skill in init["skills"] if skill in linked]

    assert len(loaded) == len(linked), sorted(set(linked) - set(loaded))
