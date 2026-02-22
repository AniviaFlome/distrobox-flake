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
        types.submodule (
          { name, ... }:
          {
            options = (lib.foldl' lib.recursiveUpdate { } (map (f: f.options) features)) // {
              aliases.name = mkOption {
                type = types.str;
                default = name;
                description = "Alias used to enter the container. Defaults to the container's name.";
              };
            };
          }
        )
      );
      default = { };
      description = "Extra configuration for distrobox containers.";
    };
  };

  config = mkMerge [
    { programs.distrobox.containers = lib.mkMerge (map mkFeatureConfig features); }
    (mkIf cfg.aliases.enable {
      home.shellAliases = mapAttrs' (
        name: containerCfg: nameValuePair containerCfg.aliases.name "distrobox enter ${name}"
      ) cfg.containers;
    })
  ];
}
