{
  description = "Home Manager module for declarative distrobox management";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    # The Home Manager module
    homeManagerModules = {
      distrobox = import ./distrobox.nix;
      default = self.homeManagerModules.distrobox;
    };
  };
}
