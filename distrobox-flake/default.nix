{ config, lib, ... }:

with lib;

let
  featureFiles = [
    ./aur.nix
    ./chaotic-aur.nix
    ./copr.nix
    ./rpmfusion.nix
  ];

  features = map (f: import f { inherit lib; }) featureFiles;

  cfg = config.programs.distrobox-flake;

  mkFeatureConfig =
    feature:
    mapAttrs (_: feature.mkContainerConfig) (filterAttrs (_: feature.hasFeature) cfg.containers);
in
{
  options.programs.distrobox-flake = {
    aliases.enable = mkEnableOption "auto-generated shell aliases for entering containers";
    containers = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = lib.foldl' lib.recursiveUpdate { } (map (f: f.options) features);
        }
      );
      default = { };
      description = "Extra configuration for distrobox containers.";
    };
  };

  config = mkMerge [
    { programs.distrobox.containers = lib.mkMerge (map mkFeatureConfig features); }
    (mkIf cfg.aliases.enable {
      home.shellAliases = mapAttrs (
        name: _: "distrobox enter ${name}"
      ) config.programs.distrobox.containers;
    })
  ];
}
