{
  lib,
  writeShellApplication,
  coreutils,
  gnugrep,
  jq,
}:
let
  mkCheck =
    name: src:
    writeShellApplication {
      name = "harness-check-${name}";
      runtimeInputs = [
        coreutils
        gnugrep
      ];
      bashOptions = [ ];
      text = builtins.readFile src;
    };

  checks = {
    no-comments = mkCheck "no-comments" ../../preferences/hooks/no-comments.sh;
    no-emdash = mkCheck "no-emdash" ../../preferences/hooks/no-emdash.sh;
  };

  mkRunner =
    names:
    writeShellApplication {
      name = "harness-check";
      runtimeInputs = [ coreutils ];
      bashOptions = [ ];
      text = ''
        checks=(${lib.escapeShellArgs (map (name: lib.getExe checks.${name}) names)})
        added=$(cat)
        for check in "''${checks[@]}"; do
          reason=$("$check" "$1" <<<"$added")
          [ -z "$reason" ] || printf '%s\n\n' "$reason"
        done
      '';
    };
in
{
  checkNames = lib.attrNames checks;

  claude-code =
    names:
    writeShellApplication {
      name = "claude-code-post-tool-use";
      runtimeInputs = [
        jq
        (mkRunner names)
      ];
      bashOptions = [ ];
      text = builtins.readFile ../../claude-code/hooks/post-tool-use.sh;
    };
}
