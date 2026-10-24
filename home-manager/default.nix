{ humanizer, mattpocock-skills }:
{
  imports = [
    (import ./claude-code.nix { inherit humanizer mattpocock-skills; })
    ./omp.nix
  ];
}
