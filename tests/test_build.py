def test_rejects_an_unknown_hook(build):
    built = build("unknown-hook")

    assert built.returncode != 0
    assert "no-such-check" in built.stderr, built.stderr


def test_rejects_an_unknown_omp_hook(build):
    built = build("omp-unknown-hook")

    assert built.returncode != 0
    assert "harness.omp.hooks.postToolUse" in built.stderr, built.stderr
    assert "is not of type" in built.stderr, built.stderr
    assert "no-such-check" in built.stderr, built.stderr


def test_rejects_a_rule_without_paths(build):
    built = build("rule-without-paths")

    assert built.returncode != 0
    assert "plain.md: a rule needs frontmatter with paths:" in built.stderr, built.stderr


def test_rejects_an_omp_rule_without_paths(build):
    built = build("omp-rule-without-paths")

    assert built.returncode != 0
    assert "plain.md: a rule needs frontmatter with paths:" in built.stderr, built.stderr


def test_rejects_mutable_settings(build):
    built = build("mutable-settings")

    assert built.returncode != 0
    assert "programs.claude-code.mutableSettings" in built.stderr, built.stderr


def test_rejects_stable_home_manager(build):
    built = build("stable-home-manager")

    assert built.returncode != 0
    assert "harness-config needs home-manager unstable" in built.stderr, built.stderr


def test_warns_that_the_version_check_is_skipped_without_a_package(build):
    built = build("test")

    assert built.returncode == 0, built.stderr
    assert "skips the claude-code version check" in built.stderr, built.stderr


def test_checks_the_version_quietly_with_a_package(build):
    built = build("with-claude-code")

    assert built.returncode == 0, built.stderr
    assert "skips the claude-code version check" not in built.stderr, built.stderr
