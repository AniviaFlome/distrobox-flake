{ lib }:

with lib;

let
  rpmfusionPreHooks =
    rpmCfg:
    optional rpmCfg.free.enable "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm || true"
    ++ optional rpmCfg.unfree.enable "sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true";

  rpmfusionInstallHooks =
    rpmCfg:
    let
      pkgs = rpmCfg.free.packages ++ rpmCfg.unfree.packages;
    in
    optional (pkgs != [ ]) "sudo dnf install -y ${concatStringsSep " " pkgs}";
in
{
  options.rpmfusion = {
    free = {
      enable = mkEnableOption "RPM Fusion Free repository (Fedora only)";
      packages = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Packages to install from RPM Fusion Free.";
      };
    };
    unfree = {
      enable = mkEnableOption "RPM Fusion Unfree repository (Fedora only)";
      packages = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Packages to install from RPM Fusion Unfree.";
      };
    };
  };

  mkContainerConfig = containerCfg: {
    pre_init_hooks = rpmfusionPreHooks containerCfg.rpmfusion;
    init_hooks = rpmfusionInstallHooks containerCfg.rpmfusion;
  };

  hasFeature =
    containerCfg: containerCfg.rpmfusion.free.enable || containerCfg.rpmfusion.unfree.enable;
}
