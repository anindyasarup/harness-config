{
  description = "uses harness-config the way another flake would, for the end-to-end tests";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    harness-config.url = "path:/harness-config";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      home-manager-stable,
      nix-darwin,
      harness-config,
      ...
    }:
    let
      homeWith =
        home-manager: module:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "claude-code";
          };
          modules = [
            harness-config.homeModules.default
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
      home = homeWith home-manager;
      alice = {
        home-manager.users.alice = {
          harness.claude-code.enable = true;
          home.stateVersion = "26.05";
        };
      };
    in
    {
      nixosConfigurations.harness = nixpkgs.lib.nixosSystem {
        modules = [
          home-manager.nixosModules.home-manager
          harness-config.nixosModules.default
          alice
          {
            nixpkgs.hostPlatform = "aarch64-linux";
            boot.isContainer = true;
            users.users.alice.isNormalUser = true;
            system.stateVersion = "26.05";
          }
        ];
      };

      darwinConfigurations.harness = nix-darwin.lib.darwinSystem {
        modules = [
          home-manager.darwinModules.home-manager
          harness-config.darwinModules.default
          alice
          {
            nixpkgs.hostPlatform = "aarch64-darwin";
            users.users.alice.home = "/Users/alice";
            system.stateVersion = 6;
          }
        ];
      };

      homeConfigurations = {
        test = home { harness.claude-code.enable = true; };
        with-claude-code = home (
          { pkgs, ... }:
          {
            harness.claude-code.enable = true;
            programs.claude-code.package = pkgs.claude-code;
            home.packages = [ pkgs.util-linux ];
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
        stable-home-manager = homeWith home-manager-stable { harness.claude-code.enable = true; };
        omp = home { harness.omp.enable = true; };
        with-omp = home (
          { pkgs, ... }:
          {
            harness.omp.enable = true;
            home.packages = [ pkgs.omp ];
          }
        );
        with-omp-model = home (
          { pkgs, ... }:
          {
            harness.omp = {
              enable = true;
              model = {
                provider = "github-copilot";
                model = "claude-sonnet-4.5";
              };
            };
            home.packages = [ pkgs.omp ];
          }
        );
        omp-model = home {
          harness.claude-code.enable = true;
          harness.omp = {
            enable = true;
            model = {
              provider = "github-copilot";
              model = "claude-sonnet-4.5";
            };
          };
        };
        omp-agent-dir = home {
          harness.omp.enable = true;
          home.sessionVariables.PI_CODING_AGENT_DIR = "/root/omp-agent";
        };
        omp-skills = home {
          harness.omp = {
            enable = true;
            skills.demo = ./skills/demo;
          };
        };
        omp-rules = home {
          harness.omp = {
            enable = true;
            rules = ./rules;
          };
        };
        rule-without-paths = home {
          harness.claude-code = {
            enable = true;
            rules = ./rules-without-paths;
          };
        };
        omp-rule-without-paths = home {
          harness.omp = {
            enable = true;
            rules = ./rules-without-paths;
          };
        };
      };

      interface =
        let
          inherit (nixpkgs) lib;
          inherit (self.homeConfigurations.test) options;
          outputs = lib.concatMap (
            output: map (name: "output ${output}.${name}") (lib.attrNames harness-config.outputs.${output})
          ) (lib.attrNames harness-config.outputs);
          harnessOptions = map (option: "option ${option.name}: ${option.type}") (
            lib.optionAttrSetToDocList options.harness
          );
          replaced =
            lib.concatMap
              (
                { configuration, folder }:
                map (file: "replaces ${file.target}") (
                  lib.filter (file: lib.hasPrefix folder file.target) (lib.attrValues configuration.config.home.file)
                )
              )
              [
                {
                  configuration = self.homeConfigurations.test;
                  folder = ".claude/";
                }
                {
                  configuration = self.homeConfigurations.omp;
                  folder = ".omp/agent/";
                }
              ];
        in
        lib.concatLines (lib.sort lib.lessThan (outputs ++ harnessOptions ++ replaced));
    };
}
