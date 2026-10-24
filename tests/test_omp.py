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


def test_sets_the_default_model_role_to_the_chosen_provider_and_model(clean_home, activate, in_container):
    activate("omp-model")

    assert read_config(in_container)["modelRoles"] == {"default": "github-copilot/claude-sonnet-4.5"}


def test_removes_the_model_it_set_once_the_model_is_unset(clean_home, activate, in_container):
    activate("omp-model")
    seed(
        in_container=in_container,
        path=CONFIG,
        text="modelRoles:\n  default: github-copilot/claude-sonnet-4.5\n  smol: openai/gpt-4.1-mini\n",
    )

    activate("omp")

    assert read_config(in_container)["modelRoles"] == {"smol": "openai/gpt-4.1-mini"}
    assert ["modelRoles", "default"] not in json.loads(in_container("cat", RECORD).stdout)


def test_leaves_claude_codes_settings_alone(clean_home, activate, in_container):
    activate("test")
    without_omp_model = in_container("cat", "/root/.claude/settings.json").stdout

    activate("omp-model")

    assert in_container("cat", "/root/.claude/settings.json").stdout == without_omp_model


def test_omp_reports_its_model_role(clean_home, activate, in_container):
    activate("with-omp-model")

    model_roles = json.loads(in_container("omp", "config", "get", "modelRoles", "--json").stdout)["value"]
    assert model_roles == {"default": "github-copilot/claude-sonnet-4.5"}


def test_links_agents_md_as_its_instructions(clean_home, activate, in_container):
    activate("omp")

    instructions = in_container("cat", "/root/.omp/agent/AGENTS.md")
    agents_md = in_container("cat", "/harness-config/preferences/AGENTS.md")

    assert instructions.returncode == 0, instructions.stderr
    assert instructions.stdout == agents_md.stdout


def test_links_its_instructions_into_the_agent_folder_variable_when_set(clean_home, activate, in_container):
    activate("omp-agent-dir")

    assert in_container("test", "-f", "/root/omp-agent/AGENTS.md").returncode == 0
    assert in_container("ls", "/root/.omp").returncode != 0


def test_replaces_an_existing_agents_md_with_a_store_link(clean_home, activate, in_container):
    seed(in_container=in_container, path="/root/.omp/agent/AGENTS.md", text="mine")

    activate("omp")

    assert in_container("readlink", "-f", "/root/.omp/agent/AGENTS.md").stdout.startswith("/nix/store/")


def linked_skills(*, in_container, folder):
    return sorted(in_container("ls", folder).stdout.split())


def test_links_the_same_skills_as_claude_code(clean_home, activate, in_container):
    activate("test")
    claude_code_skills = linked_skills(in_container=in_container, folder="/root/.claude/skills")

    activate("omp")

    assert "humanizer" in claude_code_skills
    assert linked_skills(in_container=in_container, folder="/root/.omp/agent/skills") == claude_code_skills
    outside_the_store = [
        name
        for name in claude_code_skills
        if not in_container("readlink", "-f", f"/root/.omp/agent/skills/{name}").stdout.startswith("/nix/store/")
    ]
    assert outside_the_store == []


def test_omp_lists_every_linked_skill(clean_home, activate, in_container):
    activate("with-omp")

    listed = json.loads(in_container("sh", "-c", "cd /tmp && omp skill list --json").stdout)["skills"]
    native = sorted(skill["name"] for skill in listed if skill["source"] == "native:user")

    assert "humanizer" in native
    assert native == linked_skills(in_container=in_container, folder="/root/.omp/agent/skills")


def test_links_its_skills_into_the_agent_folder_variable_when_set(clean_home, activate, in_container):
    activate("omp-agent-dir")

    assert in_container("test", "-f", "/root/omp-agent/skills/humanizer/SKILL.md").returncode == 0
    assert in_container("ls", "/root/.omp").returncode != 0


def test_links_only_the_skills_it_is_given(clean_home, activate, in_container):
    activate("omp-skills")

    assert linked_skills(in_container=in_container, folder="/root/.omp/agent/skills") == ["demo"]


def rules_omp_applies(*, in_container, tool, path):
    report = json.loads(
        in_container(
            "sh", "-c", f"cd /tmp && omp ttsr test --json --source tool --tool {tool} --path {path} 'x = 1'"
        ).stdout
    )
    return sorted(rule["name"] for rule in report["triggered"] if rule["path"].startswith("/root/.omp/agent/rules/"))


@pytest.mark.parametrize(
    ("tool", "path", "rules"),
    [
        ("edit", "/work/flake.nix", ["nix"]),
        ("write", "/work/src/app.py", ["python"]),
        ("edit", "/work/pyproject.toml", ["python"]),
        ("write", "/work/web/index.tsx", ["javascript"]),
        ("edit", "/work/README.md", []),
        ("read", "/work/flake.nix", []),
    ],
)
def test_omp_applies_each_rule_to_edits_and_writes_of_the_files_its_paths_match(
    clean_home, activate, in_container, tool, path, rules
):
    activate("with-omp")

    assert rules_omp_applies(in_container=in_container, tool=tool, path=path) == rules


def rule_texts(*, in_container, folder):
    names = in_container("ls", folder).stdout.split()
    return {name: in_container("cat", f"{folder}/{name}").stdout.split("\n---\n", 1)[1] for name in names}


def test_gives_omp_the_text_of_every_rule(clean_home, activate, in_container):
    activate("omp")

    assert rule_texts(in_container=in_container, folder="/root/.omp/agent/rules") == rule_texts(
        in_container=in_container, folder="/harness-config/preferences/instructions/rules"
    )


def test_renders_only_the_rules_it_is_given(clean_home, activate, in_container):
    activate("omp-rules")

    assert in_container("ls", "/root/.omp/agent/rules").stdout.split() == ["demo.md"]


def test_renders_its_rules_into_the_agent_folder_variable_when_set(clean_home, activate, in_container):
    activate("omp-agent-dir")

    assert in_container("test", "-f", "/root/omp-agent/rules/nix.md").returncode == 0
    assert in_container("ls", "/root/.omp").returncode != 0


def test_replaces_an_existing_rules_folder_with_a_store_link(clean_home, activate, in_container):
    seed(in_container=in_container, path="/root/.omp/agent/rules/mine.md", text="mine")

    activate("omp")

    assert in_container("readlink", "-f", "/root/.omp/agent/rules").stdout.startswith("/nix/store/")


def test_leaves_an_existing_rules_folder_alone_unless_enabled(clean_home, activate, in_container):
    seed(in_container=in_container, path="/root/.omp/agent/rules/mine.md", text="mine")

    activate("test")

    assert in_container("cat", "/root/.omp/agent/rules/mine.md").stdout == "mine"
