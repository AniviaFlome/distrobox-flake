{ lib }:

with lib;

let
  paruBootstrapCmd = concatStringsSep " " [
    "PARU_TMPDIR=$(sudo -u $USER mktemp -d) &&"
    "trap 'rm -rf $PARU_TMPDIR' EXIT &&"
    "sudo pacman -S --needed --noconfirm base-devel git &&"
    "cd $PARU_TMPDIR &&"
    "sudo -u $USER git clone https://aur.archlinux.org/paru-bin.git &&"
    "cd paru-bin &&"
    "sudo -u $USER makepkg -si --noconfirm"
  ];

  aurInitHooks =
    aurPkgs:
    optionals (aurPkgs != [ ]) [
      "command -v paru > /dev/null 2>&1 || (${paruBootstrapCmd})"
      "sudo -u $USER paru -S --needed --noconfirm ${concatStringsSep " " aurPkgs}"
    ];
in
{
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

  mkContainerConfig = containerCfg: {
    init_hooks = aurInitHooks containerCfg.aur.packages;
  };

  hasFeature = containerCfg: containerCfg.aur.enable;
}
