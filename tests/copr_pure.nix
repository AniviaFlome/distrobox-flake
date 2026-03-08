{
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (pkgs) lib;
  copr = import ../distrobox-flake/copr.nix { inherit lib; };

  testCases = {

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

  };

  results = lib.runTests testCases;
in
if results == [ ] then
  pkgs.runCommand "copr-pure-tests-passed" { } "touch $out"
else
  throw "copr pure tests failed: ${builtins.toJSON results}"
