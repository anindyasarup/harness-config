import json

import pytest

RECORD = "/root/.claude.json.managed-keys.json"


@pytest.fixture
def global_config(in_container):
    """Removes /root/.claude.json and its record before and after the test, and returns a reader for the file."""
    in_container("rm", "-f", "/root/.claude.json", RECORD)

    def read():
        return json.loads(in_container("cat", "/root/.claude.json").stdout)

    yield read
    in_container("rm", "-f", "/root/.claude.json", RECORD)


def seed(*, in_container, path, value):
    in_container("sh", "-c", f"echo '{json.dumps(value)}' > {path}")


def test_creates_global_config_with_its_settings(global_config, activate):
    activate("test")

    assert global_config() == {
        "defaultToAgentsView": True,
        "remoteControlAtStartup": False,
    }


def test_sets_its_settings_and_keeps_the_rest(global_config, activate, in_container):
    seed(
        in_container=in_container,
        path="/root/.claude.json",
        value={
            "numStartups": 3,
            "defaultToAgentsView": False,
            "projects": {"/root": {"allowedTools": []}},
        },
    )

    activate("test")
    activate("test")

    assert global_config() == {
        "numStartups": 3,
        "defaultToAgentsView": True,
        "remoteControlAtStartup": False,
        "projects": {"/root": {"allowedTools": []}},
    }


def test_leaves_global_config_alone_unless_enabled(
    global_config, activate, in_container
):
    activate("disabled")

    assert in_container("ls", "/root/.claude.json").returncode != 0


def test_removes_recorded_keys_it_no_longer_sets(global_config, activate, in_container):
    seed(
        in_container=in_container,
        path=RECORD,
        value=[["defaultToAgentsView"], ["model"], ["permissions", "defaultMode"]],
    )
    seed(
        in_container=in_container,
        path="/root/.claude.json",
        value={
            "numStartups": 3,
            "model": "opus",
            "permissions": {"defaultMode": "plan", "allow": ["Bash(ls)"]},
        },
    )

    activate("test")

    assert global_config() == {
        "numStartups": 3,
        "defaultToAgentsView": True,
        "remoteControlAtStartup": False,
        "permissions": {"allow": ["Bash(ls)"]},
    }


def test_first_activation_removes_nothing_and_records_its_keys(
    global_config, activate, in_container
):
    seed(in_container=in_container, path="/root/.claude.json", value={"model": "opus"})

    activate("test")

    assert global_config() == {
        "model": "opus",
        "defaultToAgentsView": True,
        "remoteControlAtStartup": False,
    }
    assert json.loads(in_container("cat", RECORD).stdout) == [
        ["defaultToAgentsView"],
        ["remoteControlAtStartup"],
    ]


def test_activating_twice_gives_the_same_file_and_record_as_once(
    global_config, activate, in_container
):
    seed(in_container=in_container, path=RECORD, value=[["model"]])
    seed(
        in_container=in_container,
        path="/root/.claude.json",
        value={"numStartups": 3, "model": "opus"},
    )

    activate("test")
    once = (global_config(), in_container("cat", RECORD).stdout)
    activate("test")

    assert (global_config(), in_container("cat", RECORD).stdout) == once


def test_leaves_global_config_and_record_alone_unless_enabled(
    global_config, activate, in_container
):
    seed(in_container=in_container, path=RECORD, value=[["model"]])
    seed(in_container=in_container, path="/root/.claude.json", value={"model": "opus"})

    activate("disabled")

    assert global_config() == {"model": "opus"}
    assert json.loads(in_container("cat", RECORD).stdout) == [["model"]]
