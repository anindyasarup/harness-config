{ config, lib, ... }:
let
  cfg = config.harness.omp;
  agentDir =
    config.home.sessionVariables.PI_CODING_AGENT_DIR or "${config.home.homeDirectory}/.omp/agent";
in
{
  options.harness.omp = {
    enable = lib.mkEnableOption ''
      omp support. It creates the agent folder at PI_CODING_AGENT_DIR or
      ~/.omp/agent and manages nothing in it yet
    '';
  };

  config = lib.mkIf cfg.enable {
    home.activation.createOmpAgentDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p $VERBOSE_ARG ${lib.escapeShellArg agentDir}
    '';
  };
}
