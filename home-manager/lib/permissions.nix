{
  lib,
  harness,
  rules,
}:
let
  verdictRanks = {
    never-do = 0;
    ask = 1;
    dont-ask = 2;
  };
  kinds = [
    "command"
    "read"
    "edit"
    "prose"
  ];
  withKind =
    rule:
    let
      ruleKinds = lib.intersectLists kinds (lib.attrNames rule);
    in
    lib.throwIfNot (verdictRanks ? ${rule.verdict} && lib.length ruleKinds == 1)
      "a permission rule needs one verdict of ${toString (lib.attrNames verdictRanks)} and one kind of ${toString kinds}: ${builtins.toJSON rule}"
      (rule // { kind = lib.head ruleKinds; });
  byVerdict = lib.sort (a: b: verdictRanks.${a.verdict} < verdictRanks.${b.verdict}) (
    map withKind rules
  );

  claudeCode =
    let
      lists = {
        never-do = {
          permissions = "deny";
          autoMode = "hard_deny";
        };
        ask = {
          permissions = "ask";
          autoMode = "soft_deny";
        };
        dont-ask = {
          permissions = "allow";
          autoMode = "allow";
        };
      };
      toolRule = tool: value: {
        section = "permissions";
        text = "${tool}(${value})";
      };
      renderKind = {
        command = command: toolRule "Bash" "${command} *";
        read = toolRule "Read";
        edit = toolRule "Edit";
        prose = prose: {
          section = "autoMode";
          text = prose;
        };
      };
      render =
        rule:
        let
          rendered = renderKind.${rule.kind} rule.${rule.kind};
        in
        rendered // { list = lists.${rule.verdict}.${rendered.section}; };
      textsBySection = lib.mapAttrs (
        _: sectionRules:
        lib.mapAttrs (_: map (rule: rule.text)) (lib.groupBy (rule: rule.list) sectionRules)
      ) (lib.groupBy (rule: rule.section) (map render byVerdict));
      textsIn = section: list: textsBySection.${section}.${list} or [ ];
    in
    {
      permissions = lib.genAttrs [ "allow" "ask" "deny" ] (textsIn "permissions");
      autoMode = {
        environment = [ "$defaults" ];
      }
      // lib.genAttrs [ "allow" "soft_deny" "hard_deny" ] (
        list: [ "$defaults" ] ++ textsIn "autoMode" list
      );
    };

  renderers = {
    claude-code = claudeCode;
  };
in
renderers.${harness}
