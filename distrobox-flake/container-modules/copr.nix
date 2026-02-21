{ lib, ... }:

with lib;

{
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
}
