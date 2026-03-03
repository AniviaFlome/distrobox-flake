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
          lib = nixpkgs.lib;
          eval = lib.evalModules {
            modules = [
              ./distrobox-flake
              {
                options = {
                  programs.distrobox.containers = lib.mkOption {
                    type = lib.types.attrs;
                    default = { };
                  };
                  home.shellAliases = lib.mkOption {
                    type = lib.types.attrs;
                    default = { };
                  };
                };
                config.programs.distrobox-flake = {
                  enable = true;
                  alias.enable = true;
                  containers.arch = {
                    aur.enable = true;
                    aur.packages = [ "hello" ];
                  };
                };
              }
            ];
          };
          tests = lib.runTests {
            testAurHook = {
              expr = eval.config.programs.distrobox.containers.arch.init_hooks;
              expected = [
                "command -v paru > /dev/null 2>&1 || (sudo pacman -Syu --noconfirm && sudo pacman -S --needed --noconfirm base-devel git && rm -rf /tmp/paru-bootstrap && sudo -u $USER git clone https://aur.archlinux.org/paru.git /tmp/paru-bootstrap && cd /tmp/paru-bootstrap && sudo -u $USER makepkg -si --noconfirm && rm -rf /tmp/paru-bootstrap && sudo ldconfig)"
                "sudo -u $USER paru -S --needed --noconfirm hello"
              ];
            };
            testAlias = {
              expr = eval.config.home.shellAliases;
              expected = {
                arch = "distrobox enter arch";
              };
            };
          };
        in
        {
          formatting = treefmtEval.${system}.config.build.check self;
          module-tests =
            if tests == [ ] then
              pkgs.runCommand "module-tests-passed" { } "touch $out"
            else
              throw "Module tests failed: ${builtins.toJSON tests}";
        }
      );

      homeManagerModules = {
        distrobox-flake = import ./distrobox-flake;
        default = self.homeManagerModules.distrobox-flake;
      };
    };
}
