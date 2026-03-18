{ pkgs }:

let
  testLib = import ./lib.nix { inherit pkgs; };
  inherit (testLib) mkEvalModule assertMsg;

  # Dummy packages to test with
  pkg1 = pkgs.runCommand "dummy-pkg1" { } "mkdir -p $out/bin; touch $out/bin/foo";
  pkg2 = pkgs.runCommand "dummy-pkg2" { } "mkdir -p $out/bin; touch $out/bin/bar";

  emptyConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test.packages = [ ];
  };

  packagesConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test.packages = [
      pkg1
      pkg2
    ];
  };

  emptyHooks = emptyConfig.programs.distrobox.containers.test.init_hooks or [ ];
  packagesHooks = packagesConfig.programs.distrobox.containers.test.init_hooks or [ ];

  expectedHook1 = ''[ ! -d "${pkg1}/bin" ] || sudo find "${pkg1}/bin" -mindepth 1 -maxdepth 1 \( -type f -executable -o -type l \) -exec sudo ln -sf {} /usr/local/bin/ \;'';
  expectedHook2 = ''[ ! -d "${pkg2}/bin" ] || sudo find "${pkg2}/bin" -mindepth 1 -maxdepth 1 \( -type f -executable -o -type l \) -exec sudo ln -sf {} /usr/local/bin/ \;'';

  tests = [
    (assertMsg (emptyHooks == [ ]) "empty packages should result in empty init_hooks")
    (assertMsg (builtins.length packagesHooks == 2) "two packages should result in 2 init_hooks")
    (assertMsg (
      builtins.elemAt packagesHooks 0 == expectedHook1
    ) "first hook should match expected symlink command")
    (assertMsg (
      builtins.elemAt packagesHooks 1 == expectedHook2
    ) "second hook should match expected symlink command")
  ];

  allPass = builtins.all (x: x) tests;
in
if allPass then
  pkgs.runCommand "test-packages" { } ''
    echo "All tests passed" > $out
  ''
else
  builtins.abort "Tests failed"
