{
  pkgs,
}:

let
  inherit (pkgs) lib;

  evalModule =
    configOptions:
    lib.evalModules {
      modules = [
        # Mock home-manager environment options needed by the module
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
        (_: configOptions)
      ];
    };

  cfg =
    (evalModule {
      programs.distrobox-flake = {
        enable = true;
        alias.enable = true;
        containers = {
          container-a = {
            aur.enable = true;
            # default alias name "container-a"
          };
          container-b = {
            aur.enable = true;
            alias.enable = false;
          };
          container-c = {
            aur.enable = true;
            alias.name = "custom-c";
          };
          container-d = {
            aur.enable = true;
            alias = {
              enable = true;
              name = "custom-d";
            };
          };
        };
      };
    }).config;

  cfgNoGlobalAlias =
    (evalModule {
      programs.distrobox-flake = {
        enable = true;
        alias.enable = false;
        containers = {
          container-a = {
            aur.enable = true;
          };
        };
      };
    }).config;

  cfgDisabled =
    (evalModule {
      programs.distrobox-flake = {
        enable = false;
        alias.enable = true;
        containers = {
          container-a = {
            aur.enable = true;
          };
        };
      };
    }).config;

  expectedAliases = {
    "container-a" = "distrobox enter container-a";
    "custom-c" = "distrobox enter container-c";
    "custom-d" = "distrobox enter container-d";
  };

  assertMsg = cond: msg: if cond then true else builtins.trace "FAIL: ${msg}" false;

  tests = [
    # Verify alias generation logic
    (assertMsg (cfg.home.shellAliases == expectedAliases) "Shell aliases do not match expected map")

    # Verify all containers are merged into distrobox.containers
    (assertMsg (
      cfg.programs.distrobox.containers ? container-a
    ) "container-a missing from distrobox.containers")
    (assertMsg (
      cfg.programs.distrobox.containers ? container-b
    ) "container-b missing from distrobox.containers")
    (assertMsg (
      cfg.programs.distrobox.containers ? container-c
    ) "container-c missing from distrobox.containers")
    (assertMsg (
      cfg.programs.distrobox.containers ? container-d
    ) "container-d missing from distrobox.containers")

    # Verify global alias disable works
    (assertMsg (
      cfgNoGlobalAlias.home.shellAliases == { }
    ) "Shell aliases should be empty when global alias.enable is false")

    # Verify global disable works (no containers or aliases generated)
    (assertMsg (
      cfgDisabled.programs.distrobox.containers == { }
    ) "distrobox.containers should be empty when distrobox-flake.enable is false")
    (assertMsg (
      cfgDisabled.home.shellAliases == { }
    ) "home.shellAliases should be empty when distrobox-flake.enable is false")
  ];

  allPass = builtins.all (x: x) tests;
in
if allPass then
  pkgs.runCommand "test-default" { } ''
    echo "All evaluation tests passed!"
    touch $out
  ''
else
  builtins.abort "Tests failed!"
