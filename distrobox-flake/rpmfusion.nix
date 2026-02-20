{ config, lib, ... }:

with lib;

let
  cfg = config.programs.distrobox-extra;

  rpmfusionPreHooks =
    rpmCfg:
    optional rpmCfg.free "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm || true"
    ++ optional rpmCfg.nonfree "sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true";

  containersWithRpmfusion = filterAttrs (
    _: c: c.rpmfusion.free || c.rpmfusion.nonfree
  ) cfg.containers;
in
{
  options.programs.distrobox-extra.containers = mkOption {
    type = types.attrsOf (
      types.submodule {
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
  };

  config.programs.distrobox.containers = mapAttrs (_: c: {
    pre_init_hooks = rpmfusionPreHooks c.rpmfusion;
  }) containersWithRpmfusion;
}
