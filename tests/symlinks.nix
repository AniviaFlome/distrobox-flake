{ pkgs }:

let
  inherit (pkgs) lib;
  testLib = import ./lib.nix { inherit pkgs; };
  inherit (testLib) mkEvalModule assertMsg;

  emptyConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test.symlinks = { };
  };

  symlinksConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test.symlinks = {
      "/etc/localtime" = "/var/host/etc/localtime";
      "/usr/bin/custom-script" = "/home/user/scripts/custom-script.sh";
    };
  };

  emptyHooks = emptyConfig.programs.distrobox.containers.test.init_hooks or [ ];
  symlinksHooks = symlinksConfig.programs.distrobox.containers.test.init_hooks or [ ];

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
