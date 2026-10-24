import json

import pytest
import yaml

CONFIG = "/root/.omp/agent/config.yml"
RECORD = f"{CONFIG}.managed-keys.json"


@pytest.fixture
def clean_home(in_container):
    """Removes the omp agent folders, the Claude Code folder, .claude.json and the omp work folder before and after the test."""
    folders = ["/root/.omp", "/root/omp-agent", "/root/.claude", "/root/.claude.json", "/root/work"]
    in_container("rm", "-rf", *folders)
    yield
    in_container("rm", "-rf", *folders)


def test_creates_the_default_agent_folder_and_leaves_claude_code_alone(clean_home, activate, in_container):
    activate("omp")

    assert in_container("test", "-d", "/root/.omp/agent").returncode == 0
    assert in_container("ls", "/root/.claude").returncode != 0


def read_config(in_container, path=CONFIG):
    return yaml.safe_load(in_container("cat", path).stdout)


def read_settings(in_container, path=CONFIG):
    return {key: value for key, value in read_config(in_container, path).items() if key != "bash"}


def test_creates_its_config_with_its_settings(clean_home, activate, in_container):
    activate("omp")

    assert read_settings(in_container) == {
        "defaultThinkingLevel": "medium",
        "tools": {"approvalMode": "always-ask", "approval": {"eval": "prompt"}},
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

    assert read_settings(in_container) == {
        "theme": "dark",
        "defaultThinkingLevel": "medium",
        "tools": {"approvalMode": "always-ask", "approval": {"eval": "prompt"}, "bash": ["ls"]},
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

    assert read_settings(in_container) == {
        "theme": "dark",
        "defaultThinkingLevel": "medium",
        "tools": {"approvalMode": "always-ask", "approval": {"edit": "ask", "eval": "prompt"}},
    }


def test_first_activation_removes_nothing_and_records_its_keys(clean_home, activate, in_container):
    seed(in_container=in_container, path=CONFIG, text="modelRoles:\n  default: x/y\n")

    activate("omp")

    assert read_settings(in_container) == {
        "modelRoles": {"default": "x/y"},
        "defaultThinkingLevel": "medium",
        "tools": {"approvalMode": "always-ask", "approval": {"eval": "prompt"}},
    }
    assert json.loads(in_container("cat", RECORD).stdout) == [
        ["bash", "patterns"],
        ["defaultThinkingLevel"],
        ["tools", "approval", "eval"],
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

    assert read_settings(in_container, "/root/omp-agent/config.yml") == {
        "defaultThinkingLevel": "medium",
        "tools": {"approvalMode": "always-ask", "approval": {"eval": "prompt"}},
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


def test_replaces_existing_keybindings_with_an_empty_store_link(clean_home, activate, in_container):
    seed(in_container=in_container, path="/root/.omp/agent/keybindings.yml", text="app.tools.expand: ctrl+x\n")

    activate("omp")

    assert in_container("readlink", "-f", "/root/.omp/agent/keybindings.yml").stdout.startswith("/nix/store/")
    assert read_config(in_container, "/root/.omp/agent/keybindings.yml") == {}


def test_links_its_keybindings_into_the_agent_folder_variable_when_set(clean_home, activate, in_container):
    activate("omp-agent-dir")

    assert read_config(in_container, "/root/omp-agent/keybindings.yml") == {}
    assert in_container("ls", "/root/.omp").returncode != 0


def test_leaves_an_existing_rules_folder_alone_unless_enabled(clean_home, activate, in_container):
    seed(in_container=in_container, path="/root/.omp/agent/rules/mine.md", text="mine")

    activate("test")

    assert in_container("cat", "/root/.omp/agent/rules/mine.md").stdout == "mine"


def tool_result(*, in_container, call, edit_mode="replace", cwd="/root/work"):
    session = in_container(
        "sh",
        "-c",
        'cd "$1" && PI_EDIT_VARIANT="$2" SCRIPTED_TOOL_CALL="$3" omp -p --mode json'
        " -e /consumer/omp/scripted-provider.ts --model scripted/scripted --approval-mode yolo go",
        "sh",
        cwd,
        edit_mode,
        json.dumps(call),
    )
    events = [json.loads(line) for line in session.stdout.splitlines() if line.startswith("{")]
    ends = [event for event in events if event["type"] == "tool_execution_end"]
    assert len(ends) == 1, session.stdout + session.stderr
    return ends[0]


def reported(result):
    return "\n".join(chunk["text"] for chunk in result["result"]["content"] if chunk["type"] == "text")


@pytest.mark.parametrize(
    ("on_disk", "call", "edit_mode", "reason"),
    [
        pytest.param(
            None,
            {"name": "write", "arguments": {"path": "notes.md", "content": "a — b\n"}},
            "replace",
            "Em-dash added in /root/work/notes.md",
            id="an em-dash in a written file",
        ),
        pytest.param(
            ("edited.py", "x = 1\ny = 2\n"),
            {
                "name": "edit",
                "arguments": {"path": "edited.py", "old_string": "y = 2\n", "new_string": "y = 2  # set y\n"},
            },
            "replace",
            "1 comment(s) introduced in /root/work/edited.py",
            id="a comment added by an edit",
        ),
        pytest.param(
            ("patched.md", "a\n"),
            {
                "name": "edit",
                "arguments": {"input": "*** Begin Patch\n*** Update File: patched.md\n@@\n-a\n+a — b\n*** End Patch\n"},
            },
            "apply_patch",
            "Em-dash added in /root/work/patched.md",
            id="an em-dash added by a patch",
        ),
    ],
)
def test_omp_reports_a_failing_check_after_a_write_or_edit(
    clean_home, activate, in_container, on_disk, call, edit_mode, reason
):
    activate("with-omp")
    in_container("mkdir", "-p", "/root/work")
    if on_disk:
        seed(in_container=in_container, path=f"/root/work/{on_disk[0]}", text=on_disk[1])

    result = tool_result(in_container=in_container, call=call, edit_mode=edit_mode)

    assert result["isError"] is True, result
    assert reason in reported(result), reported(result)


@pytest.mark.parametrize(
    ("on_disk", "call"),
    [
        pytest.param(
            None,
            {"name": "write", "arguments": {"path": "clean.py", "content": "x = 1\n"}},
            id="a clean written file",
        ),
        pytest.param(
            ("kept.py", "x = 1  # set x\ny = 2\n"),
            {"name": "edit", "arguments": {"path": "kept.py", "old_string": "y = 2\n", "new_string": "y = 3\n"}},
            id="a clean edit to a file with comments",
        ),
    ],
)
def test_omp_passes_a_clean_write_or_edit_untouched(clean_home, activate, in_container, on_disk, call):
    activate("with-omp")
    in_container("mkdir", "-p", "/root/work")
    if on_disk:
        seed(in_container=in_container, path=f"/root/work/{on_disk[0]}", text=on_disk[1])

    result = tool_result(in_container=in_container, call=call)

    assert result["isError"] is False, result
    assert len(result["result"]["content"]) == 1, result


def test_omp_runs_only_the_checks_it_is_given(clean_home, activate, in_container):
    activate("with-omp-hooks")
    in_container("mkdir", "-p", "/root/work")

    result = tool_result(
        in_container=in_container,
        call={"name": "write", "arguments": {"path": "mixed.py", "content": "x = 1  # set x\ny = 'a — b'\n"}},
    )

    assert "Em-dash added" in reported(result), reported(result)
    assert "comment(s) introduced" not in reported(result), reported(result)


def test_replaces_an_existing_hooks_folder_with_a_store_link(clean_home, activate, in_container):
    seed(in_container=in_container, path="/root/.omp/agent/hooks/post/mine.ts", text="mine")

    activate("omp")

    assert in_container("readlink", "-f", "/root/.omp/agent/hooks").stdout.startswith("/nix/store/")
    assert in_container("ls", "/root/.omp/agent/hooks/post").stdout.split() == ["harness-check.ts"]


def test_links_its_hooks_into_the_agent_folder_variable_when_set(clean_home, activate, in_container):
    activate("omp-agent-dir")

    assert in_container("test", "-f", "/root/omp-agent/hooks/post/harness-check.ts").returncode == 0
    assert in_container("ls", "/root/.omp").returncode != 0


def test_leaves_an_existing_hooks_folder_alone_unless_enabled(clean_home, activate, in_container):
    seed(in_container=in_container, path="/root/.omp/agent/hooks/post/mine.ts", text="mine")

    activate("test")

    assert in_container("cat", "/root/.omp/agent/hooks/post/mine.ts").stdout == "mine"


APPROVALS = {"deny": "deny", "ask": "prompt", "allow": "allow"}


def claude_code_commands(*, activate, in_container):
    activate("test")
    permissions = json.loads(in_container("cat", "/root/.claude/settings.json").stdout)["permissions"]
    return {
        APPROVALS[name]: [
            rule.removeprefix("Bash(").removesuffix(" *)") for rule in permissions[name] if rule.startswith("Bash(")
        ]
        for name in APPROVALS
    }


def test_refuses_asks_about_and_allows_the_same_commands_as_claude_code(clean_home, activate, in_container):
    commands = claude_code_commands(activate=activate, in_container=in_container)

    activate("omp")

    patterns = read_config(in_container)["bash"]["patterns"]
    rendered = [
        {"match": match, "approval": approval}
        for approval in ["deny", "prompt", "allow"]
        for command in commands[approval]
        for match in [command, f"{command} *"]
    ]
    assert [pattern for pattern in patterns if pattern in rendered] == rendered


def test_orders_its_shell_patterns_deny_then_prompt_then_allow(clean_home, activate, in_container):
    activate("omp")

    approvals = [pattern["approval"] for pattern in read_config(in_container)["bash"]["patterns"]]

    assert approvals == sorted(approvals, key=["deny", "prompt", "allow"].index)
    assert set(approvals) == {"deny", "prompt", "allow"}


def test_refuses_piping_into_a_shell_and_asks_before_shells_from_the_eval_tool(clean_home, activate, in_container):
    activate("omp")

    config = read_config(in_container)

    missing = [shell for shell in ["sh", "bash", "zsh"] if {"match": shell, "approval": "deny"} not in config["bash"]["patterns"]]
    assert missing == []
    assert config["tools"]["approval"]["eval"] == "prompt"


def test_omp_reports_its_shell_patterns_and_eval_approval(clean_home, activate, in_container):
    activate("with-omp")

    def setting(key):
        return json.loads(in_container("omp", "config", "get", key, "--json").stdout)["value"]

    assert setting("bash.patterns") == read_config(in_container)["bash"]["patterns"]
    assert setting("tools.approval") == {"eval": "prompt"}


@pytest.fixture
def secrets(in_container):
    """Seeds a file at every Never do read path. Removes those files and /root/outside before and after the test."""
    paths = ["/root/.ssh", "/root/.gnupg", "/root/.aws", "/root/.config/gh", "/root/.netrc", "/root/outside"]
    in_container("rm", "-rf", *paths)
    for path in ["/root/.ssh/id_test", "/root/.gnupg/key", "/root/.aws/credentials", "/root/.config/gh/hosts.yml", "/root/.netrc"]:
        seed(in_container=in_container, path=path, text="secret")
    yield
    in_container("rm", "-rf", *paths)


@pytest.mark.parametrize(
    "path",
    ["~/.ssh/id_test", "~/.gnupg/key", "~/.aws/credentials", "~/.config/gh/hosts.yml", "/root/.netrc", "file:///root/.ssh/id_test"],
)
def test_omp_refuses_reading_a_never_do_path_with_the_read_tool(clean_home, secrets, activate, in_container, path):
    activate("with-omp")
    in_container("mkdir", "-p", "/root/work")

    result = tool_result(in_container=in_container, call={"name": "read", "arguments": {"path": path}})

    assert result["isError"] is True, result
    assert "Never do" in reported(result), reported(result)
    assert "secret" not in reported(result), reported(result)


@pytest.mark.parametrize(
    "command",
    ["cat ~/.ssh/id_test", 'head -n1 "$HOME/.aws/credentials"', "base64 /root/.netrc", "cp ${HOME}/.gnupg/key k && cat k"],
)
def test_omp_refuses_a_shell_command_that_names_a_never_do_path(clean_home, secrets, activate, in_container, command):
    activate("with-omp")
    in_container("mkdir", "-p", "/root/work")

    result = tool_result(in_container=in_container, call={"name": "bash", "arguments": {"command": command}})

    assert result["isError"] is True, result
    assert "Never do" in reported(result), reported(result)
    assert "secret" not in reported(result), reported(result)


@pytest.fixture
def repo(in_container):
    """Makes /root/work a git repo with a pkg folder and a .env at its root, and puts a .env.local in /root/outside."""
    in_container("mkdir", "-p", "/root/work/pkg")
    in_container("git", "init", "-q", "/root/work")
    seed(in_container=in_container, path="/root/work/.env", text="inside")
    seed(in_container=in_container, path="/root/outside/.env.local", text="leaked")


@pytest.mark.parametrize(
    "call",
    [
        pytest.param({"name": "read", "arguments": {"path": "/root/outside/.env.local"}}, id="read tool"),
        pytest.param({"name": "bash", "arguments": {"command": "cat ../../outside/.env.local"}}, id="shell"),
    ],
)
def test_omp_refuses_a_env_file_outside_the_repo(clean_home, secrets, repo, activate, in_container, call):
    activate("with-omp")

    result = tool_result(in_container=in_container, call=call, cwd="/root/work/pkg")

    assert result["isError"] is True, result
    assert ".env file outside the repo" in reported(result), reported(result)
    assert "leaked" not in reported(result), reported(result)


@pytest.mark.parametrize(
    "call",
    [
        pytest.param({"name": "read", "arguments": {"path": "../.env"}}, id="read tool"),
        pytest.param({"name": "bash", "arguments": {"command": "cat ../.env"}}, id="shell"),
    ],
)
def test_omp_reads_a_env_file_anywhere_in_the_repo(clean_home, secrets, repo, activate, in_container, call):
    activate("with-omp")

    result = tool_result(in_container=in_container, call=call, cwd="/root/work/pkg")

    assert result["isError"] is False, result
    assert "inside" in reported(result), reported(result)


@pytest.mark.parametrize(
    "call",
    [
        pytest.param({"name": "read", "arguments": {"path": "/root/outside/notes.txt"}}, id="read tool"),
        pytest.param({"name": "bash", "arguments": {"command": "cat ~/outside/notes.txt"}}, id="shell"),
    ],
)
def test_omp_still_reads_other_files_outside_the_repo(clean_home, secrets, activate, in_container, call):
    activate("with-omp")
    in_container("mkdir", "-p", "/root/work")
    seed(in_container=in_container, path="/root/outside/notes.txt", text="notes")

    result = tool_result(in_container=in_container, call=call)

    assert result["isError"] is False, result
    assert "notes" in reported(result), reported(result)


@pytest.mark.parametrize(
    ("cwd", "path", "refused"),
    [
        pytest.param("/root/outside", ".env.local", False, id="in the working folder"),
        pytest.param("/root/outside/pkg", "../.env.local", True, id="above the working folder"),
    ],
)
def test_omp_treats_the_working_folder_as_the_repo_outside_a_git_repo(
    clean_home, secrets, activate, in_container, cwd, path, refused
):
    activate("with-omp")
    in_container("mkdir", "-p", "/root/outside/pkg")
    seed(in_container=in_container, path="/root/outside/.env.local", text="outside")

    result = tool_result(in_container=in_container, call={"name": "read", "arguments": {"path": path}}, cwd=cwd)

    assert result["isError"] is refused, result
