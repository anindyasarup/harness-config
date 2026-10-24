import json

import pytest
import yaml

CONFIG = "/root/.omp/agent/config.yml"
RECORD = f"{CONFIG}.managed-keys.json"


@pytest.fixture
def clean_home(in_container):
    """Removes the omp agent folders, the Claude Code folder and .claude.json before and after the test."""
    folders = ["/root/.omp", "/root/omp-agent", "/root/.claude", "/root/.claude.json"]
    in_container("rm", "-rf", *folders)
    yield
    in_container("rm", "-rf", *folders)


def test_creates_the_default_agent_folder_and_leaves_claude_code_alone(clean_home, activate, in_container):
    activate("omp")

    assert in_container("test", "-d", "/root/.omp/agent").returncode == 0
    assert in_container("ls", "/root/.claude").returncode != 0


def read_config(in_container, path=CONFIG):
    return yaml.safe_load(in_container("cat", path).stdout)


def test_creates_its_config_with_its_settings(clean_home, activate, in_container):
    activate("omp")

    assert read_config(in_container) == {
        "defaultThinkingLevel": "medium",
        "tools": {"approvalMode": "always-ask"},
    }


def seed(*, in_container, path, text):
    in_container("sh", "-c", f"mkdir -p $(dirname {path}) && printf '%s' '{text}' > {path}")


def test_sets_its_settings_and_keeps_the_rest(clean_home, activate, in_container):
    seed(
        in_container=in_container,
        path=CONFIG,
        text="theme: dark\ndefaultThinkingLevel: high\ntools:\n  approvalMode: yolo\n  bash: [ls]\n",
    )

    activate("omp")
    activate("omp")

    assert read_config(in_container) == {
        "theme": "dark",
        "defaultThinkingLevel": "medium",
        "tools": {"approvalMode": "always-ask", "bash": ["ls"]},
    }


@pytest.mark.parametrize("text", ["tools: [\n", "- theme\n", "false\n"])
def test_fails_and_leaves_a_config_it_cant_read_alone(clean_home, try_activate, in_container, text):
    seed(in_container=in_container, path=CONFIG, text=text)
    before = in_container("cat", CONFIG).stdout

    activated = try_activate("omp")

    assert activated.returncode != 0
    assert in_container("cat", CONFIG).stdout == before
    assert in_container("sh", "-c", f"ls {CONFIG}.*").stdout.strip() == ""


def test_removes_recorded_keys_it_no_longer_sets(clean_home, activate, in_container):
    seed(in_container=in_container, path=RECORD, text='[["defaultThinkingLevel"], ["tools", "bash"], ["modelRoles"]]')
    seed(
        in_container=in_container,
        path=CONFIG,
        text="theme: dark\nmodelRoles:\n  default: x/y\ntools:\n  bash: [ls]\n  approval:\n    edit: ask\n",
    )

    activate("omp")

    assert read_config(in_container) == {
        "theme": "dark",
        "defaultThinkingLevel": "medium",
        "tools": {"approvalMode": "always-ask", "approval": {"edit": "ask"}},
    }


def test_first_activation_removes_nothing_and_records_its_keys(clean_home, activate, in_container):
    seed(in_container=in_container, path=CONFIG, text="modelRoles:\n  default: x/y\n")

    activate("omp")

    assert read_config(in_container) == {
        "modelRoles": {"default": "x/y"},
        "defaultThinkingLevel": "medium",
        "tools": {"approvalMode": "always-ask"},
    }
    assert json.loads(in_container("cat", RECORD).stdout) == [
        ["defaultThinkingLevel"],
        ["tools", "approvalMode"],
    ]


def test_activating_twice_gives_the_same_file_and_record_as_once(clean_home, activate, in_container):
    seed(in_container=in_container, path=RECORD, text='[["modelRoles"]]')
    seed(in_container=in_container, path=CONFIG, text="# mine\ntheme: dark\nmodelRoles:\n  default: x/y\n")

    activate("omp")
    once = (in_container("cat", CONFIG).stdout, in_container("cat", RECORD).stdout)
    activate("omp")

    assert (in_container("cat", CONFIG).stdout, in_container("cat", RECORD).stdout) == once


def test_leaves_its_config_and_record_alone_unless_enabled(clean_home, activate, in_container):
    seed(in_container=in_container, path=RECORD, text='[["modelRoles"]]')
    seed(in_container=in_container, path=CONFIG, text="modelRoles:\n  default: x/y\n")

    activate("test")

    assert read_config(in_container) == {"modelRoles": {"default": "x/y"}}
    assert json.loads(in_container("cat", RECORD).stdout) == [["modelRoles"]]


def test_uses_the_agent_folder_variable_when_set(clean_home, activate, in_container):
    activate("omp-agent-dir")

    assert read_config(in_container, "/root/omp-agent/config.yml") == {
        "defaultThinkingLevel": "medium",
        "tools": {"approvalMode": "always-ask"},
    }
    assert in_container("ls", "/root/.omp").returncode != 0


def test_writes_nothing_to_omp_unless_enabled(clean_home, activate, in_container):
    activate("test")

    assert in_container("ls", "/root/.omp").returncode != 0


def test_doesnt_install_omp(clean_home, activate, in_container):
    activate("omp")

    assert in_container("omp", "--version").returncode != 0


def test_omp_reports_its_settings(clean_home, activate, in_container):
    activate("with-omp")

    def setting(key):
        return json.loads(in_container("omp", "config", "get", key, "--json").stdout)["value"]

    assert setting("defaultThinkingLevel") == "medium"
    assert setting("tools.approvalMode") == "always-ask"
    assert setting("modelRoles") == {}
