{
  description = "uses harness-config the way another flake would, for the end-to-end tests";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    harness-config.url = "path:/harness-config";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      harness-config,
      ...
    }:
    let
      home =
        module:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "claude-code";
          };
          modules = [
            harness-config.homeManagerModules.default
            {
              home = {
                username = "root";
                homeDirectory = "/root";
                stateVersion = "26.05";
              };
            }
            module
          ];
        };
    in
    {
      homeConfigurations = {
        test = home { harness.claude-code.enable = true; };
        with-claude-code = home (
          { pkgs, ... }:
          {
            harness.claude-code.enable = true;
            programs.claude-code.package = pkgs.claude-code;
          }
        );
        disabled = home { programs.claude-code.enable = true; };
        unknown-hook = home {
          harness.claude-code = {
            enable = true;
            hooks.postToolUse = [ "no-such-check" ];
          };
        };
        mutable-settings = home {
          harness.claude-code.enable = true;
          programs.claude-code.mutableSettings = true;
        };
        rule-without-paths = home {
          harness.claude-code = {
            enable = true;
            rules = ./rules-without-paths;
          };
        };
      };
    };
}
