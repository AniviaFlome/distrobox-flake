{ pkgs }:

let
  testLib = import ./lib.nix { inherit pkgs; };
  inherit (testLib) mkEvalModule assertMsg;

  mkCoprConfig =
    repos: packages:
    mkEvalModule {
      programs.distrobox-flake.enable = true;
      programs.distrobox-flake.containers.test = {
        copr.enable = true;
        copr.repos = repos;
        copr.packages = packages;
      };
    };

  emptyConfig = mkCoprConfig [ ] [ ];
  reposConfig = mkCoprConfig [ "atim/starship" "group/repo" ] [ ];
  packagesConfig = mkCoprConfig [ ] [ "foo" "bar" ];
  bothConfig = mkCoprConfig [ "atim/starship" ] [ "starship" ];

  emptyPreHooks = emptyConfig.programs.distrobox.containers.test.pre_init_hooks or [ ];
  emptyInitHooks = emptyConfig.programs.distrobox.containers.test.init_hooks or [ ];

  reposPreHooks = reposConfig.programs.distrobox.containers.test.pre_init_hooks or [ ];

  packagesInitHooks = packagesConfig.programs.distrobox.containers.test.init_hooks or [ ];

  bothPreHooks = bothConfig.programs.distrobox.containers.test.pre_init_hooks or [ ];
  bothInitHooks = bothConfig.programs.distrobox.containers.test.init_hooks or [ ];

  tests = [
    (assertMsg (emptyPreHooks == [ ]) "empty repos should result in empty pre_init_hooks")
    (assertMsg (emptyInitHooks == [ ]) "empty packages should result in empty init_hooks")

    (assertMsg (builtins.length reposPreHooks == 2) "non-empty repos should result in 2 pre_init_hooks")
    (assertMsg (
      builtins.elemAt reposPreHooks 0 == "sudo dnf copr enable -y atim/starship"
    ) "first repo command should match")
    (assertMsg (
      builtins.elemAt reposPreHooks 1 == "sudo dnf copr enable -y group/repo"
    ) "second repo command should match")

    (assertMsg (
      builtins.length packagesInitHooks == 1
    ) "non-empty packages should result in 1 init_hook")
    (assertMsg (
      builtins.elemAt packagesInitHooks 0 == "sudo dnf install -y foo bar"
    ) "the package list should be included in the dnf install command")

    (assertMsg (builtins.length bothPreHooks == 1) "both configured should have 1 pre_init_hook")
    (assertMsg (
      builtins.elemAt bothPreHooks 0 == "sudo dnf copr enable -y atim/starship"
    ) "both configured pre_init_hook should match")
    (assertMsg (builtins.length bothInitHooks == 1) "both configured should have 1 init_hook")
    (assertMsg (
      builtins.elemAt bothInitHooks 0 == "sudo dnf install -y starship"
    ) "both configured init_hook should match")
  ];

  allPass = builtins.all (x: x) tests;
in
if allPass then
  pkgs.runCommand "test-copr" { } ''
    echo "All tests passed" > $out
  ''
else
  builtins.abort "Tests failed"
