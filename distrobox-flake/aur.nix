{ config, lib, ... }:

with lib;

let
  cfg = config.programs.distrobox-extra;

  paruBootstrapCmd = concatStringsSep " && " [
    "sudo pacman -S --needed --noconfirm base-devel git"
    "cd /tmp"
    "git clone https://aur.archlinux.org/paru-bin.git"
    "cd paru-bin"
    "makepkg -si --noconfirm"
    "cd /tmp"
    "rm -rf paru-bin"
  ];

  aurInitHooks =
    aurPkgs:
    optionals (aurPkgs != [ ]) [
      "command -v paru > /dev/null 2>&1 || (${paruBootstrapCmd})"
      "paru -S --needed --noconfirm ${concatStringsSep " " aurPkgs}"
    ];

  containersWithAur = filterAttrs (_: c: c.aur.enable) cfg.containers;
in
{
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
      }
    );
    default = { };
  };

  config.programs.distrobox.containers = mapAttrs (_: c: {
    init_hooks = aurInitHooks c.aur.packages;
  }) containersWithAur;
}
