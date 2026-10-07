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
    {
      homeConfigurations.test = home-manager.lib.homeManagerConfiguration {
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
            harness.claude-code.enable = true;
          }
        ];
      };
    };
}
