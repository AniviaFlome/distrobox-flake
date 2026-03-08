{
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (pkgs) lib;
  rpmfusion = import ../distrobox-flake/rpmfusion.nix { inherit lib; };

  testCases = {
    testHasFeatureBothEnabled = {
      expr = rpmfusion.hasFeature {
        rpmfusion = {
          free.enable = true;
          unfree.enable = true;
        };
      };
      expected = true;
    };

    testHasFeatureFreeEnabled = {
      expr = rpmfusion.hasFeature {
        rpmfusion = {
          free.enable = true;
          unfree.enable = false;
        };
      };
      expected = true;
    };

    testHasFeatureUnfreeEnabled = {
      expr = rpmfusion.hasFeature {
        rpmfusion = {
          free.enable = false;
          unfree.enable = true;
        };
      };
      expected = true;
    };

    testHasFeatureNoneEnabled = {
      expr = rpmfusion.hasFeature {
        rpmfusion = {
          free.enable = false;
          unfree.enable = false;
        };
      };
      expected = false;
    };

    testMkContainerConfigBothEnabledWithPackages = {
      expr = rpmfusion.mkContainerConfig {
        rpmfusion = {
          free = {
            enable = true;
            packages = [
              "vlc"
              "ffmpeg"
            ];
          };
          unfree = {
            enable = true;
            packages = [ "steam" ];
          };
        };
      };
      expected = {
        pre_init_hooks = [
          "test -f /etc/yum.repos.d/rpmfusion-free.repo || sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
          "test -f /etc/yum.repos.d/rpmfusion-nonfree.repo || sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
        ];
        init_hooks = [
          "sudo dnf install -y vlc ffmpeg steam"
        ];
      };
    };

    testMkContainerConfigFreeOnlyNoPackages = {
      expr = rpmfusion.mkContainerConfig {
        rpmfusion = {
          free = {
            enable = true;
            packages = [ ];
          };
          unfree = {
            enable = false;
            packages = [ ];
          };
        };
      };
      expected = {
        pre_init_hooks = [
          "test -f /etc/yum.repos.d/rpmfusion-free.repo || sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
        ];
        init_hooks = [ ];
      };
    };

    testMkContainerConfigUnfreeOnlyNoPackages = {
      expr = rpmfusion.mkContainerConfig {
        rpmfusion = {
          free = {
            enable = false;
            packages = [ ];
          };
          unfree = {
            enable = true;
            packages = [ ];
          };
        };
      };
      expected = {
        pre_init_hooks = [
          "test -f /etc/yum.repos.d/rpmfusion-nonfree.repo || sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
        ];
        init_hooks = [ ];
      };
    };

    testMkContainerConfigNoneEnabledNoPackages = {
      expr = rpmfusion.mkContainerConfig {
        rpmfusion = {
          free = {
            enable = false;
            packages = [ ];
          };
          unfree = {
            enable = false;
            packages = [ ];
          };
        };
      };
      expected = {
        pre_init_hooks = [ ];
        init_hooks = [ ];
      };
    };
  };

  results = lib.runTests testCases;
in
if results == [ ] then
  pkgs.runCommand "rpmfusion-tests-passed" { } "touch $out"
else
  throw "rpmfusion tests failed: ${builtins.toJSON results}"
