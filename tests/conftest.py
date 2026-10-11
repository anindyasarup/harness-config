import subprocess

import pytest


def just(*args):
    return subprocess.run(["just", *args], capture_output=True, text=True)


@pytest.fixture(scope="session")
def container():
    """Starts a fresh nixos/nix container before the first test that needs it, replacing any left running, and stops it after the last."""
    just("down")
    up = just("up")
    assert up.returncode == 0, up.stderr
    yield
    just("down")


@pytest.fixture
def build(container):
    """Builds a homeConfigurations.<config> from the consumer flake inside the container without activating it, and returns the result."""
    return lambda config: just("build", config)


@pytest.fixture
def activate(container):
    """Builds and activates a homeConfigurations.<config> from the consumer flake inside the container."""

    def run(config):
        activated = just("activate", config)
        assert activated.returncode == 0, activated.stdout + activated.stderr

    return run


@pytest.fixture
def in_container(container):
    """Runs a command inside the container and returns its exit code and output."""
    return lambda *command: just("exec", *command)
