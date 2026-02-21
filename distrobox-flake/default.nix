{ config, lib, ... }:

with lib;

{
  imports = [
    ./aur.nix
    ./chaotic-aur.nix
    ./copr.nix
    ./rpmfusion.nix
  ];

  options.programs.distrobox-extra.containers = mkOption {
    type = types.attrsOf (
      types.submoduleWith {
        modules = [
          ./container-modules/aur.nix
          ./container-modules/chaotic-aur.nix
          ./container-modules/copr.nix
          ./container-modules/rpmfusion.nix
        ];
      }
    );
    default = { };
    description = "Extra configuration for distrobox containers.";
  };
}
