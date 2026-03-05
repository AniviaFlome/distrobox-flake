{ lib }:

let
  rpmfusionPreHooks =
    rpmCfg:
    lib.optional rpmCfg.free.enable "test -f /etc/yum.repos.d/rpmfusion-free.repo || sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    ++ lib.optional rpmCfg.unfree.enable "test -f /etc/yum.repos.d/rpmfusion-nonfree.repo || sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm";

  rpmfusionInstallHooks =
    rpmCfg:
    let
      pkgs = rpmCfg.free.packages ++ rpmCfg.unfree.packages;
    in
    lib.optional (pkgs != [ ]) "sudo dnf install -y ${lib.escapeShellArgs pkgs}";
in
{
  options.rpmfusion = {
    free = {
      enable = lib.mkEnableOption "RPM Fusion Free repository (Fedora only)";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Packages to install from RPM Fusion Free.";
      };
    };
    unfree = {
      enable = lib.mkEnableOption "RPM Fusion Unfree repository (Fedora only)";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
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
