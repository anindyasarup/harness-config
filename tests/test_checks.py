import os
import subprocess
from pathlib import Path

import pytest

samples = Path(__file__).parent / "hooks"
checks = sorted((Path(__file__).parent.parent / "preferences" / "hooks").glob("*.sh"))
env = {name: value for name, value in os.environ.items() if name != "ALLOW_COMMENTS"}


def files(kind):
    return [pytest.param(path, id=str(path.relative_to(samples))) for path in sorted((samples / kind).rglob("*")) if path.is_file()]


def report(sample):
    """Runs every check on a sample as if the whole file had just been written, and returns what they print."""
    output = ""
    for check in checks:
        with sample.open() as added:
            run = subprocess.run(["bash", check, sample], stdin=added, capture_output=True, text=True, env=env)
        assert run.returncode == 0, (check.name, run.stderr)
        output += run.stdout
    return output


@pytest.mark.parametrize("sample", files("blocks"))
def test_checks_report_sample(sample):
    assert report(sample) != ""


@pytest.mark.parametrize("sample", files("passes"))
def test_checks_pass_sample(sample):
    assert report(sample) == ""
