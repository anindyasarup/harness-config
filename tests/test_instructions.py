def test_claude_code_loads_agents_md_as_claude_md(activate, in_container):
    activate("test")

    context = in_container("claude", "-p", "/context")
    claude_md = in_container("cat", "/root/.claude/CLAUDE.md")
    agents_md = in_container("cat", "/harness-config/preferences/AGENTS.md")

    assert "| User | /root/.claude/CLAUDE.md |" in context.stdout, context.stdout
    assert claude_md.stdout == agents_md.stdout
