{
  pkgs,
}:

let
  testLib = import ./lib.nix { inherit pkgs; };
  inherit (testLib) mkEvalModule assertMsg;

  cfg = mkEvalModule {
    programs.distrobox-flake = {
      enable = true;
      alias.enable = true;
      containers = {
        container-a = {
          aur.enable = true;
          aur.packages = [ "some-pkg" ];
          # default alias name "container-a"
        };
        container-b = {
          aur.enable = true;
          aur.packages = [ "some-pkg" ];
          alias.enable = false;
        };
        container-c = {
          aur.enable = true;
          aur.packages = [ "some-pkg" ];
          alias.name = "custom-c";
        };
        container-d = {
          aur.enable = true;
          aur.packages = [ "some-pkg" ];
          alias = {
            enable = true;
            name = "custom-d";
          };
        };
      };
    };
  };

  cfgNoGlobalAlias = mkEvalModule {
    programs.distrobox-flake = {
      enable = true;
      alias.enable = false;
      containers = {
        container-a = {
          aur.enable = true;
          aur.packages = [ "some-pkg" ];
        };
      };
    };
  };

  cfgDisabled = mkEvalModule {
    programs.distrobox-flake = {
      enable = false;
      alias.enable = true;
      containers = {
        container-a = {
          aur.enable = true;
          aur.packages = [ "some-pkg" ];
        };
      };
    };
  };

  expectedAliases = {
    "container-a" = "distrobox enter container-a";
    "custom-c" = "distrobox enter container-c";
    "custom-d" = "distrobox enter container-d";
  };

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
    echo "All tests passed" > $out
  ''
else
  builtins.abort "Tests failed"
