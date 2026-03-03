{
  pkgs,
}:

let
  inherit (pkgs) lib;
  module = ../distrobox-flake/default.nix;

  eval = lib.evalModules {
    modules = [
      module
      {
        options = {
          programs.distrobox.containers = lib.mkOption {
            type = lib.types.attrsOf lib.types.unspecified;
            default = { };
          };
          home.shellAliases = lib.mkOption {
            type = lib.types.attrsOf lib.types.unspecified;
            default = { };
          };
        };

        config = {
          programs.distrobox-flake = {
            enable = true;
            alias.enable = true;
            containers = {
              my-container = {
                aur.enable = true;
                alias.name = "mc";
              };
              no-alias-container = {
                copr.enable = true;
                alias.enable = false;
              };
            };
          };
        };
      }
    ];
  };

  cfg = eval.config;

  # Define expected logic output
  expectedAliases = {
    "mc" = "distrobox enter my-container";
  };

  # Check logic
  assert1 =
    lib.asserts.assertMsg (cfg.home.shellAliases == expectedAliases)
      "Shell aliases do not match expected";
  assert2 =
    lib.asserts.assertMsg (cfg.programs.distrobox.containers ? my-container)
      "my-container missing from distrobox.containers";
  assert3 =
    lib.asserts.assertMsg (cfg.programs.distrobox.containers ? no-alias-container)
      "no-alias-container missing from distrobox.containers";
in
if assert1 && assert2 && assert3 then
  pkgs.runCommand "eval-tests" { } ''
    echo "All evaluation tests passed!"
    touch $out
  ''
else
  throw "Tests failed!"
