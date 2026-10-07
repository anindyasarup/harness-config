import json

import pytest


@pytest.mark.parametrize(
    ("on_disk", "tool_input", "reason"),
    [
        pytest.param(
            "{}",
            {"notebook_path": "/tmp/hook/code.ipynb", "cell_type": "code", "new_source": "# load\nx = 1"},
            "comment(s) introduced",
            id="blocks a comment in a notebook code cell",
        ),
        pytest.param(
            "{}",
            {"notebook_path": "/tmp/hook/prose.ipynb", "cell_type": "markdown", "new_source": "# Heading"},
            None,
            id="passes a notebook markdown cell",
        ),
        pytest.param(
            "x = 1  # set x\n",
            {"file_path": "/tmp/hook/kept.py", "old_string": "y = 2\n", "new_string": ""},
            None,
            id="passes an edit adding no text to a file with comments",
        ),
    ],
)
def test_post_tool_use_hook(on_disk, tool_input, reason, activate, in_container):
    activate("test")

    path = tool_input.get("file_path") or tool_input["notebook_path"]
    hook = in_container(
        "sh",
        "-c",
        'mkdir -p "$(dirname "$1")" && printf %s "$2" > "$1" && printf %s "$3" | /root/.claude/hooks/post-tool-use',
        "sh",
        path,
        on_disk,
        json.dumps({"tool_input": tool_input}),
    )

    assert hook.returncode == 0, hook.stderr
    if reason is None:
        assert hook.stdout == "", hook.stdout
    else:
        decision = json.loads(hook.stdout)
        assert decision["decision"] == "block", decision
        assert reason in decision["reason"], decision["reason"]
