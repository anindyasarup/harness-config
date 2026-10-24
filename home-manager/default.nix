{ humanizer, mattpocock-skills }:
{
  imports = [
    (import ./claude-code { inherit humanizer mattpocock-skills; })
    (import ./omp { inherit humanizer mattpocock-skills; })
  ];
}
