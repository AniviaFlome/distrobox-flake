{ pkgs }:

let
  testLib = import ./lib.nix { inherit pkgs; };
  inherit (testLib) mkEvalModule assertMsg;

  emptyConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test = {
      aur.enable = true;
      aur.packages = [ ];
    };
  };

  packagesConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test = {
      aur.enable = true;
      aur.packages = [
        "foo"
        "bar"
      ];
    };
  };

  emptyHooks = emptyConfig.programs.distrobox.containers.test.init_hooks or [ ];
  packagesHooks = packagesConfig.programs.distrobox.containers.test.init_hooks or [ ];

  tests = [
    (assertMsg (emptyHooks == [ ]) "empty packages should result in empty init_hooks")
    (assertMsg (builtins.length packagesHooks == 2) "non-empty packages should result in 2 init_hooks")
    (assertMsg (
      builtins.match ".*sudo -u \"\\$USER\" paru -S --needed --noconfirm foo bar.*" (
        builtins.elemAt packagesHooks 1
      ) != null
    ) "the package list should be included in the paru command")
  ];

  allPass = builtins.all (x: x) tests;
in
if allPass then
  pkgs.runCommand "test-aur" { } ''
    echo "All tests passed" > $out
  ''
else
  builtins.abort "Tests failed"
