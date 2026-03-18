{ pkgs }:

let
  testLib = import ./lib.nix { inherit pkgs; };
  inherit (testLib) mkEvalModule assertMsg;

  emptyConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test = {
      chaotic-aur.enable = true;
      chaotic-aur.packages = [ ];
    };
  };

  packagesConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test = {
      chaotic-aur.enable = true;
      chaotic-aur.packages = [
        "foo"
        "bar"
      ];
    };
  };

  emptyHooks = emptyConfig.programs.distrobox.containers.test.init_hooks or [ ];
  packagesHooks = packagesConfig.programs.distrobox.containers.test.init_hooks or [ ];

  tests = [
    (assertMsg (builtins.length emptyHooks == 1) "empty packages should result in 1 init_hook")
    (assertMsg (builtins.length packagesHooks == 2) "non-empty packages should result in 2 init_hooks")
    (assertMsg (
      builtins.match ".*sudo pacman -S --needed --noconfirm foo bar.*" (builtins.elemAt packagesHooks 1)
      != null
    ) "the package list should be included in the pacman command")
  ];

  allPass = builtins.all (x: x) tests;
in
if allPass then
  pkgs.runCommand "test-chaotic-aur" { } ''
    echo "All tests passed" > $out
  ''
else
  builtins.abort "Tests failed"
