{ pkgs }:

let
  inherit (pkgs) lib;

  # Create a minimal evaluation wrapper to test the packages.nix file
  evalModule =
    packages:
    lib.evalModules {
      modules = [
        # Dummy programs.distrobox definition to avoid errors
        (
          { lib, ... }:
          {
            options.programs.distrobox = {
              enable = lib.mkEnableOption "dummy";
              containers = lib.mkOption {
                type = lib.types.attrs;
                default = { };
              };
            };
            options.home.shellAliases = lib.mkOption {
              type = lib.types.attrs;
              default = { };
            };
          }
        )
        ../distrobox-flake/default.nix
        (_: {
          programs.distrobox-flake.enable = true;
          programs.distrobox-flake.containers.test = {
            inherit packages;
          };
        })
      ];
    };

  # Dummy packages to test with
  pkg1 = pkgs.runCommand "dummy-pkg1" { } "mkdir -p $out/bin; touch $out/bin/foo";
  pkg2 = pkgs.runCommand "dummy-pkg2" { } "mkdir -p $out/bin; touch $out/bin/bar";

  emptyConfig = evalModule [ ];
  packagesConfig = evalModule [
    pkg1
    pkg2
  ];

  # The output hooks are stored in programs.distrobox.containers.test.init_hooks
  emptyHooks = emptyConfig.config.programs.distrobox.containers.test.init_hooks or [ ];
  packagesHooks = packagesConfig.config.programs.distrobox.containers.test.init_hooks or [ ];

  assertMsg = cond: msg: if cond then true else builtins.trace "FAIL: ${msg}" false;

  # Expected string generation for package symlinking
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
