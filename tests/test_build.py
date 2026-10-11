def test_rejects_an_unknown_hook(build):
    built = build("unknown-hook")

    assert built.returncode != 0
    assert "no-such-check" in built.stderr, built.stderr


def test_rejects_a_rule_without_paths(build):
    built = build("rule-without-paths")

    assert built.returncode != 0
    assert "plain.md: a rule needs frontmatter with paths:" in built.stderr, built.stderr


def test_rejects_mutable_settings(build):
    built = build("mutable-settings")

    assert built.returncode != 0
    assert "programs.claude-code.mutableSettings" in built.stderr, built.stderr
