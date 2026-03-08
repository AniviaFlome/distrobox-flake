{ lib }:

let
  copr = import ../distrobox-flake/copr.nix { inherit lib; };
in
lib.runTests {

  testCoprPreHooksEmpty = {
    expr = copr._coprPreHooks [ ];
    expected = [ ];
  };

  testCoprPreHooksSingle = {
    expr = copr._coprPreHooks [ "atim/starship" ];
    expected = [ "sudo dnf copr enable -y atim/starship" ];
  };

  testCoprPreHooksMultiple = {
    expr = copr._coprPreHooks [
      "atim/starship"
      "ngompa/snapd"
    ];
    expected = [
      "sudo dnf copr enable -y atim/starship"
      "sudo dnf copr enable -y ngompa/snapd"
    ];
  };

  testCoprInstallHookEmpty = {
    expr = copr._coprInstallHook [ ];
    expected = [ ];
  };

  testCoprInstallHookSingle = {
    expr = copr._coprInstallHook [ "starship" ];
    expected = [ "sudo dnf install -y starship" ];
  };

  testCoprInstallHookMultiple = {
    expr = copr._coprInstallHook [
      "starship"
      "snapd"
    ];
    expected = [ "sudo dnf install -y starship snapd" ];
  };

}
