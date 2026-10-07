def test_rejects_an_unknown_hook(build):
    built = build("unknown-hook")

    assert built.returncode != 0
    assert "no-such-check" in built.stderr, built.stderr
