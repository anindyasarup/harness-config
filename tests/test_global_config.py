import json

import pytest


@pytest.fixture
def global_config(in_container):
    """Removes /root/.claude.json before and after the test, and returns a reader for it."""
    in_container("rm", "-f", "/root/.claude.json")

    def read():
        return json.loads(in_container("cat", "/root/.claude.json").stdout)

    yield read
    in_container("rm", "-f", "/root/.claude.json")


def test_creates_global_config_with_its_settings(global_config, activate):
    activate("test")

    assert global_config() == {"defaultToAgentsView": True, "remoteControlAtStartup": False}


def test_sets_its_settings_and_keeps_the_rest(global_config, activate, in_container):
    seeded = {"numStartups": 3, "defaultToAgentsView": False, "projects": {"/root": {"allowedTools": []}}}
    in_container("sh", "-c", f"echo '{json.dumps(seeded)}' > /root/.claude.json")

    activate("test")
    activate("test")

    assert global_config() == {
        "numStartups": 3,
        "defaultToAgentsView": True,
        "remoteControlAtStartup": False,
        "projects": {"/root": {"allowedTools": []}},
    }


def test_leaves_global_config_alone_unless_enabled(global_config, activate, in_container):
    activate("disabled")

    assert in_container("ls", "/root/.claude.json").returncode != 0
