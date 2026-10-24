{ humanizer, mattpocock-skills }:
{
  imports = [
    (import ./claude-code.nix { inherit humanizer mattpocock-skills; })
    (import ./omp.nix { inherit humanizer mattpocock-skills; })
  ];
}
