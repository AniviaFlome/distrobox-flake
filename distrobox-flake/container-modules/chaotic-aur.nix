{ lib, ... }:

with lib;

{
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
}
