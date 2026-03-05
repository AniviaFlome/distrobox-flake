{ config, lib, ... }:

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
    lib.mapAttrs (_: feature.mkContainerConfig) (
      lib.filterAttrs (_: feature.hasFeature) cfg.containers
    );
in
{
  options.programs.distrobox-flake = {
    enable = lib.mkEnableOption "distrobox-flake integration";
    alias.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Shell alias for entering containers.";
    };
    containers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = (lib.foldl' lib.recursiveUpdate { } (map (f: f.options) features)) // {
              alias = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Shell alias for this container.";
                };
                name = lib.mkOption {
                  type = lib.types.str;
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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      { programs.distrobox.containers = lib.mkMerge (map mkFeatureConfig features); }
      (lib.mkIf cfg.alias.enable {
        home.shellAliases = lib.mapAttrs' (
          name: containerCfg: lib.nameValuePair containerCfg.alias.name "distrobox enter ${name}"
        ) (lib.filterAttrs (_: c: c.alias.enable) cfg.containers);
      })
    ]
  );
}
