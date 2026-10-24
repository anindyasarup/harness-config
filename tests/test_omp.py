import json

import pytest


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


def test_uses_the_agent_folder_variable_when_set(clean_home, activate, in_container):
    activate("omp-agent-dir")

    assert in_container("test", "-d", "/root/omp-agent").returncode == 0
    assert in_container("ls", "/root/.omp").returncode != 0


def test_writes_nothing_to_omp_unless_enabled(clean_home, activate, in_container):
    activate("test")

    assert in_container("ls", "/root/.omp").returncode != 0


def test_doesnt_install_omp(clean_home, activate, in_container):
    activate("omp")

    assert in_container("omp", "--version").returncode != 0


def test_omp_runs_on_its_own_defaults(clean_home, activate, in_container):
    activate("with-omp")

    def setting(key):
        return json.loads(in_container("omp", "config", "get", key, "--json").stdout)["value"]

    assert setting("defaultThinkingLevel") == "high"
    assert setting("tools.approvalMode") == "yolo"
    assert setting("modelRoles") == {}
