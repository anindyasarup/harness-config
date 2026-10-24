let
  commands =
    verdict:
    map (command: {
      inherit verdict command;
    });
in
commands "dont-ask" [
  "nix flake check"
  "nix flake show"
  "nix flake metadata"
  "nix eval"
  "nix fmt"
  "nix develop"
  "nix search"
]
++ commands "ask" [
  "nix build"
  "nix run"
  "nix shell"
  "nix-collect-garbage"
  "nix store gc"
]
++ commands "never-do" [
  "darwin-rebuild switch"
  "home-manager switch"
  "nix flake update"
  "nix profile install"
  "nix profile add"
  "nix-env -i"
]
++ [
  {
    verdict = "never-do";
    edit = "//**/flake.lock";
  }
]
