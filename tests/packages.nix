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

  allPackagesConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test.allPackages.enable = true;
  };

  allAndExplicitConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test = {
      packages = [ pkg1 ];
      allPackages.enable = true;
    };
  };

  emptyHooks = emptyConfig.programs.distrobox.containers.test.init_hooks or [ ];
  packagesHooks = packagesConfig.programs.distrobox.containers.test.init_hooks or [ ];
  allPackagesHooks = allPackagesConfig.programs.distrobox.containers.test.init_hooks or [ ];
  allAndExplicitHooks = allAndExplicitConfig.programs.distrobox.containers.test.init_hooks or [ ];

  expectedHook1 = ''[ ! -d "${pkg1}/bin" ] || sudo find "${pkg1}/bin" -mindepth 1 -maxdepth 1 \( -type f -executable -o -type l \) -exec sudo ln -sf {} /usr/local/bin/ \;'';
  expectedHook2 = ''[ ! -d "${pkg2}/bin" ] || sudo find "${pkg2}/bin" -mindepth 1 -maxdepth 1 \( -type f -executable -o -type l \) -exec sudo ln -sf {} /usr/local/bin/ \;'';
  expectedAllHook = ''[ ! -d "$HOME/.nix-profile/bin" ] || sudo find "$HOME/.nix-profile/bin" -mindepth 1 -maxdepth 1 \( -type f -executable -o -type l \) -exec sudo ln -sf {} /usr/local/bin/ \;'';

  tests = [
    (assertMsg (emptyHooks == [ ]) "empty packages should result in empty init_hooks")
    (assertMsg (builtins.length packagesHooks == 2) "two packages should result in 2 init_hooks")
    (assertMsg (
      builtins.elemAt packagesHooks 0 == expectedHook1
    ) "first hook should match expected symlink command")
    (assertMsg (
      builtins.elemAt packagesHooks 1 == expectedHook2
    ) "second hook should match expected symlink command")

    (assertMsg (builtins.length allPackagesHooks == 1) "allPackages.enable should produce 1 init_hook")
    (assertMsg (
      builtins.elemAt allPackagesHooks 0 == expectedAllHook
    ) "allPackages hook should symlink from ~/.nix-profile/bin")

    (assertMsg (
      builtins.length allAndExplicitHooks == 2
    ) "allPackages + explicit package should produce 2 init_hooks")
    (assertMsg (
      builtins.elemAt allAndExplicitHooks 0 == expectedHook1
    ) "explicit package hook should come first")
    (assertMsg (
      builtins.elemAt allAndExplicitHooks 1 == expectedAllHook
    ) "allPackages hook should come second")
  ];

  allPass = builtins.all (x: x) tests;
in
if allPass then
  pkgs.runCommand "test-packages" { } ''
    echo "All tests passed" > $out
  ''
else
  builtins.abort "Tests failed"
