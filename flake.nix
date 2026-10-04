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
          rumdlConfig = (pkgs.formats.toml { }).generate ".rumdl.toml" {
            global.line-length = 80;
            MD003.style = "atx";
            MD004.style = "dash";
            MD013 = {
              reflow = true;
              code-blocks = false;
            };
            MD035.style = "---";
            MD046.style = "fenced";
            MD048.style = "backtick";
            MD049.style = "asterisk";
            MD050.style = "asterisk";
            MD060 = {
              enabled = true;
              style = "aligned";
            };
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
                rumdl = {
                  glob = "*.md";
                  run = "rumdl check --fix --no-cache --config ${rumdlConfig} {staged_files}";
                  stage_fixed = true;
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
              pkgs.rumdl
            ];

            shellHook = ''
              ln -sf ${lefthookConfig} .lefthook.yaml
              ln -sf ${rumdlConfig} .rumdl.toml
              lefthook install
            '';
          };
        };
    };
}
