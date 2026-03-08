{ pkgs }:

let
  inherit (pkgs) lib;

  # Create a minimal evaluation wrapper to test the symlinks.nix file
  evalModule =
    symlinks:
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
            inherit symlinks;
          };
        })
      ];
    };

  emptyConfig = evalModule { };
  symlinksConfig = evalModule {
    "/etc/localtime" = "/var/host/etc/localtime";
    "/usr/bin/custom-script" = "/home/user/scripts/custom-script.sh";
  };

  # The output hooks are stored in programs.distrobox.containers.test.init_hooks
  emptyHooks = emptyConfig.config.programs.distrobox.containers.test.init_hooks or [ ];
  symlinksHooks = symlinksConfig.config.programs.distrobox.containers.test.init_hooks or [ ];

  assertMsg = cond: msg: if cond then true else builtins.trace "FAIL: ${msg}" false;

  # We use lib.any or manually check since the generated hooks order might vary if mapAttrsToList is used,
  # but actually mapAttrsToList returns list sorted by key or similar? No, let's just check length and elements.

  expectedHook1 = ''sudo mkdir -p "$(dirname ${lib.escapeShellArg "/etc/localtime"})" && sudo ln -sf ${lib.escapeShellArg "/var/host/etc/localtime"} ${lib.escapeShellArg "/etc/localtime"}'';
  expectedHook2 = ''sudo mkdir -p "$(dirname ${lib.escapeShellArg "/usr/bin/custom-script"})" && sudo ln -sf ${lib.escapeShellArg "/home/user/scripts/custom-script.sh"} ${lib.escapeShellArg "/usr/bin/custom-script"}'';

  tests = [
    (assertMsg (emptyHooks == [ ]) "empty symlinks should result in empty init_hooks")
    (assertMsg (builtins.length symlinksHooks == 2) "non-empty symlinks should result in 2 init_hooks")
    (assertMsg (builtins.elem expectedHook1 symlinksHooks) "hook1 should be present")
    (assertMsg (builtins.elem expectedHook2 symlinksHooks) "hook2 should be present")
  ];

  allPass = builtins.all (x: x) tests;
in
if allPass then
  pkgs.runCommand "test-symlinks" { } ''
    echo "All tests passed" > $out
  ''
else
  builtins.abort "Tests failed"
