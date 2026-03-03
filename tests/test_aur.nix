{ pkgs }:

let
  inherit (pkgs) lib;

  # Create a minimal evaluation wrapper to test the aur.nix file
  evalModule = packages:
    lib.evalModules {
      modules = [
        # Dummy programs.distrobox definition to avoid errors
        ({ config, lib, ... }: {
          options.programs.distrobox = {
             enable = lib.mkEnableOption "dummy";
             containers = lib.mkOption { type = lib.types.attrs; default = {}; };
          };
          options.home.shellAliases = lib.mkOption { type = lib.types.attrs; default = {}; };
        })
        ../distrobox-flake/default.nix
        ({ ... }: {
          programs.distrobox-flake.enable = true;
          programs.distrobox-flake.containers.test = {
            aur.enable = true;
            aur.packages = packages;
          };
        })
      ];
    };

  emptyConfig = evalModule [];
  packagesConfig = evalModule ["foo" "bar"];

  # The output hooks are stored in programs.distrobox.containers.test.init_hooks
  emptyHooks = emptyConfig.config.programs.distrobox.containers.test.init_hooks or [];
  packagesHooks = packagesConfig.config.programs.distrobox.containers.test.init_hooks or [];

  assertMsg = cond: msg: if cond then true else builtins.trace "FAIL: ${msg}" false;

  tests = [
    (assertMsg (emptyHooks == []) "empty packages should result in empty init_hooks")
    (assertMsg (builtins.length packagesHooks == 2) "non-empty packages should result in 2 init_hooks")
    (assertMsg (builtins.match ".*sudo -u \\$USER paru -S --needed --noconfirm foo bar.*" (builtins.elemAt packagesHooks 1) != null) "the package list should be included in the paru command")
  ];

  allPass = builtins.all (x: x) tests;
in
  if allPass then
    pkgs.runCommand "test-aur" {} ''
      echo "All tests passed" > $out
    ''
  else
    builtins.abort "Tests failed"
