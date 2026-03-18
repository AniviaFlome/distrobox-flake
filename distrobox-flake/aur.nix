{ lib }:

let
  paruBootstrapCmd = lib.concatStringsSep " && " [
    "sudo pacman -Syu --noconfirm"
    "sudo pacman -S --needed --noconfirm base-devel git"
    "tempdir=$(sudo -u \"$USER\" mktemp -d)"
    "sudo -u \"$USER\" git clone https://aur.archlinux.org/paru.git \"$tempdir\""
    "cd \"$tempdir\""
    "sudo -u \"$USER\" makepkg -si --noconfirm"
    "cd /"
    "rm -rf \"$tempdir\""
    "sudo ldconfig"
  ];

  aurInitHooks =
    aurPkgs:
    lib.optionals (aurPkgs != [ ]) [
      "command -v paru > /dev/null 2>&1 || (${paruBootstrapCmd})"
      "sudo -u \"$USER\" paru -S --needed --noconfirm ${lib.escapeShellArgs aurPkgs}"
    ];
in
{
  options.aur = {
    enable = lib.mkEnableOption "AUR package support (Arch containers only)";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
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

  hasFeature = containerCfg: containerCfg.aur.enable && containerCfg.aur.packages != [ ];
}
