{ lib }:

with lib;

let
  chaoticSetupCmd = concatStringsSep " && " [
    "sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com"
    "sudo pacman-key --lsign-key 3056513887B78AEB"
    "sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'"
    "sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'"
    ''grep -q '^\[chaotic-aur\]' /etc/pacman.conf || printf '\n[chaotic-aur]\nInclude = /etc/pacman/chaotic-mirrorlist\n' | sudo tee -a /etc/pacman.conf''
    "sudo pacman -Sy"
  ];

  chaoticInitHooks =
    packages:
    [
      "grep -q '^\[chaotic-aur\]' /etc/pacman.conf || (${chaoticSetupCmd})"
    ]
    ++ optional (
      packages != [ ]
    ) "sudo pacman -S --needed --noconfirm ${concatStringsSep " " packages}";
in
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

  mkContainerConfig = containerCfg: {
    init_hooks = chaoticInitHooks containerCfg.chaotic-aur.packages;
  };

  hasFeature = containerCfg: containerCfg.chaotic-aur.enable;
}
