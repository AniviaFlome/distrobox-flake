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

  hello-pkg = pkgs.writeTextDir "bin/hello" "echo hello";
  git-pkg = pkgs.writeTextDir "bin/git" "echo git";

  emptyConfig = evalModule [ ];
  packagesConfig = evalModule [
    hello-pkg
    git-pkg
  ];

  emptyHooks = emptyConfig.config.programs.distrobox.containers.test.init_hooks or [ ];
  packagesHooks = packagesConfig.config.programs.distrobox.containers.test.init_hooks or [ ];

  assertMsg = cond: msg: if cond then true else builtins.trace "FAIL: ${msg}" false;

  # Create strings without contexts to compare easily
  hook0 = builtins.unsafeDiscardStringContext (builtins.elemAt packagesHooks 0);
  hook1 = builtins.unsafeDiscardStringContext (builtins.elemAt packagesHooks 1);
  helloPath = builtins.unsafeDiscardStringContext (builtins.toString hello-pkg);
  gitPath = builtins.unsafeDiscardStringContext (builtins.toString git-pkg);

  # Use hasInfix to avoid regex store path checks
  tests = [
    (assertMsg (emptyHooks == [ ]) "empty packages should result in empty init_hooks")
    (assertMsg (builtins.length packagesHooks == 2) "non-empty packages should result in 2 init_hooks")
    (assertMsg (lib.hasInfix "sudo find \"${helloPath}/bin\"" hook0) "the package path should be included in the find command for hook0")
    (assertMsg (lib.hasInfix "sudo find \"${gitPath}/bin\"" hook1) "the package path should be included in the find command for hook1")
  ];

  allPass = builtins.all (x: x) tests;
in
if allPass then
  pkgs.runCommand "test-packages" { } ''
    echo "All tests passed" > $out
  ''
else
  builtins.abort "Tests failed"
