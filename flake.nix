{
  description = "flake for my harness configuration";

  inputs = {
    humanizer = {
      url = "github:blader/humanizer";
      flake = false;
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
  };

  outputs =
    { humanizer, mattpocock-skills, ... }:
    let
      module = import ./home-manager { inherit humanizer mattpocock-skills; };
    in
    {
      homeModules.default = module;
      homeManagerModules.default = module;
      darwinModules.default = {
        home-manager.sharedModules = [ module ];
      };
      nixosModules.default = {
        home-manager.sharedModules = [ module ];
      };
    };
}
