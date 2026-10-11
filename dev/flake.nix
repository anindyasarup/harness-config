{
  description = "Internal test flake for harness-config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, git-hooks, ... }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      betterleaksConfig = (pkgs.formats.toml { }).generate ".betterleaks.toml" {
        title = "harness-config-rules";
        extend.useDefault = true;
      };
      rumdlSettings = {
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
      rumdlConfig = (pkgs.formats.toml { }).generate ".rumdl.toml" rumdlSettings;
      preCommit = git-hooks.lib.aarch64-darwin.run {
        src = ./.;
        package = pkgs.prek;
        hooks = {
          nixfmt = {
            enable = true;
            priority = 0;
          };
          rumdl = {
            enable = true;
            settings.configuration = rumdlSettings;
            args = [
              "--fix"
              "--no-cache"
            ];
            priority = 0;
          };
          statix = {
            enable = true;
            priority = 1;
          };
          deadnix = {
            enable = true;
            priority = 1;
          };
          betterleaks = {
            enable = true;
            name = "betterleaks";
            package = pkgs.betterleaks;
            entry = "${pkgs.lib.getExe pkgs.betterleaks} git --pre-commit --staged --config ${betterleaksConfig}";
            pass_filenames = false;
            priority = 1;
          };
        };
      };
    in
    {
      devShells.aarch64-darwin.default = pkgs.mkShell {
        packages = [
          pkgs.just
          pkgs.uv
          pkgs.container
        ]
        ++ preCommit.enabledPackages;

        shellHook = ''
          find . -maxdepth 1 -name '.*' -type l -lname '/nix/store/*' ! -name .pre-commit-config.yaml -delete
          ${preCommit.shellHook}
          ln -sf ${rumdlConfig} .rumdl.toml
          uv sync --quiet
          source .venv/bin/activate
        '';
      };
    };
}
