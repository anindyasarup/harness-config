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
    {
      homeManagerModules.default = import ./home-manager { inherit humanizer mattpocock-skills; };
    };
}
