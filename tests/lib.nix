{ pkgs }:

let
  inherit (pkgs) lib;

  mockHmModule =
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
    };

  mkEvalModule =
    configOptions:
    (lib.evalModules {
      modules = [
        mockHmModule
        ../distrobox-flake/default.nix
        (_: configOptions)
      ];
    }).config;

  assertMsg = cond: msg: if cond then true else builtins.trace "FAIL: ${msg}" false;
in
{
  inherit
    mockHmModule
    mkEvalModule
    assertMsg
    ;
}
