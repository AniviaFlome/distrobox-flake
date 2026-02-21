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
      types.submodule {
        options.aur = {
          enable = mkEnableOption "AUR package support (Arch containers only)";

          packages = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "AUR packages to install. Paru is bootstrapped automatically.";
            example = [
              "paru-bin"
              "visual-studio-code-bin"
            ];
          };
        };

        options.chaotic-aur = {
          enable = mkEnableOption "Chaotic AUR repository support (Arch containers only)";

          packages = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Packages to install from the Chaotic AUR repository.";
            example = [
              "firefox-kde-opensuse"
              "rate-mirrors"
            ];
          };
        };

        options.copr = {
          enable = mkEnableOption "COPR repository support (Fedora containers only)";

          repos = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "COPR repositories to enable. Enabled before package installation.";
            example = [ "atim/starship" ];
          };

          packages = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Packages to install from COPR repositories.";
            example = [ "starship" ];
          };
        };

        options.rpmfusion = {
          free = mkOption {
            type = types.bool;
            default = false;
            description = "Enable RPM Fusion Free repository (Fedora only).";
          };
          nonfree = mkOption {
            type = types.bool;
            default = false;
            description = "Enable RPM Fusion Nonfree repository (Fedora only).";
          };
        };
      }
    );
    default = { };
    description = "Extra configuration for distrobox containers.";
  };
}
