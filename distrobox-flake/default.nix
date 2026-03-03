{ config, lib, ... }:

with lib;

let
  featureFiles = [
    ./aur.nix
    ./chaotic-aur.nix
    ./copr.nix
    ./rpmfusion.nix
    ./packages.nix
    ./symlinks.nix
  ];

  features = map (f: import f { inherit lib; }) featureFiles;

  cfg = config.programs.distrobox-flake;

  mkFeatureConfig =
    feature:
    mapAttrs (_: feature.mkContainerConfig) (filterAttrs (_: feature.hasFeature) cfg.containers);
in
{
  options.programs.distrobox-flake = {
    enable = mkEnableOption "distrobox-flake integration";
    alias.enable = mkEnableOption "Shell alias for entering containers";
    containers = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = (lib.foldl' lib.recursiveUpdate { } (map (f: f.options) features)) // {
              alias = {
                enable = mkEnableOption "shell alias for this container" // {
                  default = true;
                };
                name = mkOption {
                  type = types.str;
                  default = name;
                  description = "Alias used to enter the container. Defaults to the container's name.";
                };
              };
            };
          }
        )
      );
      default = { };
      description = "Extra configuration for distrobox containers.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { programs.distrobox.containers = lib.mkMerge (map mkFeatureConfig features); }
    (mkIf cfg.alias.enable {
      home.shellAliases = mapAttrs' (
        name: containerCfg: nameValuePair containerCfg.alias.name "distrobox enter ${name}"
      ) (filterAttrs (_: c: c.alias.enable) cfg.containers);
    })
  ]);
}
