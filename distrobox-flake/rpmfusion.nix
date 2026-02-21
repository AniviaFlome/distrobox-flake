{ lib }:

with lib;

let
  rpmfusionPreHooks =
    rpmCfg:
    optional rpmCfg.free "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm || true"
    ++ optional rpmCfg.nonfree "sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true";
in
{
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

  mkContainerConfig = containerCfg: {
    pre_init_hooks = rpmfusionPreHooks containerCfg.rpmfusion;
  };

  hasFeature = containerCfg: containerCfg.rpmfusion.free || containerCfg.rpmfusion.nonfree;
}
