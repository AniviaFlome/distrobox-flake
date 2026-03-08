{
  description = "Extension module for home-manager's programs.distrobox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      treefmtEval = forAllSystems (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
    in
    {
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          coprTestResults = import ./tests/default.nix { inherit (nixpkgs) lib; };
        in
        {
          formatting = treefmtEval.${system}.config.build.check self;
          test-default = import ./tests/test_default.nix { inherit pkgs; };
          test-aur = import ./tests/test_aur.nix { inherit pkgs; };
          test-packages = import ./tests/test_packages.nix { inherit pkgs; };
          test-chaotic-aur = import ./tests/test_chaotic_aur.nix { inherit pkgs; };
          test-symlinks = import ./tests/test_symlinks.nix { inherit pkgs; };
          test-copr = import ./tests/test_copr.nix { inherit pkgs; };
          test-rpmfusion = import ./tests/test_rpmfusion.nix { inherit pkgs; };
          test-copr-pure =
            if coprTestResults == [ ] then
              pkgs.runCommand "copr-tests-passed" { } "touch $out"
            else
              throw "COPR tests failed: ${builtins.toJSON coprTestResults}";
        }
      );

      homeManagerModules = {
        distrobox-flake = import ./distrobox-flake;
        default = self.homeManagerModules.distrobox-flake;
      };
    };
}
