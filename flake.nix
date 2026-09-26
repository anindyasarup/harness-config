{
  description = "flake for my harness configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
      ];

      perSystem =
        {
          pkgs,
          ...
        }:
        let
          betterleaksConfig = (pkgs.formats.toml { }).generate ".betterleaks.toml" {
            title = "harness-config-rules";
            extend.useDefault = true;
          };
          lefthookConfig = (pkgs.formats.yaml { }).generate ".lefthook.yaml" {
            pre-commit = {
              parallel = true;
              skip = [
                "merge"
                "rebase"
              ];
              commands = {
                betterleaks.run = "betterleaks git --pre-commit --staged --config ${betterleaksConfig}";
                statix.run = "statix check";
                deadnix.run = "deadnix --fail";
                nixfmt = {
                  glob = "*.nix";
                  run = "treefmt --fail-on-change";
                };
              };
            };
          };
        in
        {
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.just
              pkgs.lefthook
              pkgs.betterleaks
              pkgs.statix
              pkgs.deadnix
              pkgs.nixfmt-tree
            ];

            shellHook = ''
              ln -sf ${lefthookConfig} .lefthook.yaml
              lefthook install
            '';
          };
        };
    };
}
