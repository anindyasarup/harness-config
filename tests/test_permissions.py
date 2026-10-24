import json

AUTO_MODE_LISTS = ["environment", "allow", "soft_deny", "hard_deny"]


def settings(activate, in_container):
    activate("test")
    return json.loads(in_container("cat", "/root/.claude/settings.json").stdout)


def test_every_auto_mode_list_keeps_the_built_in_rules(activate, in_container):
    auto_mode = settings(activate, in_container)["autoMode"]

    assert sorted(auto_mode) == sorted(AUTO_MODE_LISTS)
    for name in AUTO_MODE_LISTS:
        assert "$defaults" in auto_mode[name], name


def test_auto_mode_environment_holds_only_the_built_in_rules(activate, in_container):
    assert settings(activate, in_container)["autoMode"]["environment"] == ["$defaults"]


def test_no_rule_is_both_allowed_and_refused_or_asked(activate, in_container):
    configured = settings(activate, in_container)
    permissions = configured["permissions"]
    auto_mode = configured["autoMode"]

    assert permissions["allow"]
    assert permissions["ask"]
    assert set(permissions["allow"]) & set(permissions["deny"]) == set()
    assert set(permissions["allow"]) & set(permissions["ask"]) == set()
    assert set(auto_mode["allow"]) & set(auto_mode["hard_deny"]) == {"$defaults"}
    assert set(auto_mode["allow"]) & set(auto_mode["soft_deny"]) == {"$defaults"}


def test_keeps_the_default_permission_mode(activate, in_container):
    assert settings(activate, in_container)["permissions"]["defaultMode"] == "default"


def test_claude_code_reports_its_rules_on_top_of_the_built_in_ones(activate, in_container, claude):
    activate("with-claude-code")

    auto_mode = json.loads(in_container("cat", "/root/.claude/settings.json").stdout)["autoMode"]
    defaults = json.loads(claude("auto-mode", "defaults").stdout)
    effective = json.loads(claude("auto-mode", "config").stdout)

    for name in AUTO_MODE_LISTS:
        configured = set(auto_mode[name]) - {"$defaults"}
        assert set(effective[name]) == set(defaults[name]) | configured, name
    assert len(effective["allow"]) > len(defaults["allow"])
