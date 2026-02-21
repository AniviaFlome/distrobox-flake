{ lib }:

with lib;

let
  coprPreHooks = repos: map (repo: "sudo dnf copr enable -y ${repo}") repos;

  coprInstallHook =
    packages: optional (packages != [ ]) "sudo dnf install -y ${concatStringsSep " " packages}";
in
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

  mkContainerConfig = containerCfg: {
    pre_init_hooks = coprPreHooks containerCfg.copr.repos;
    init_hooks = coprInstallHook containerCfg.copr.packages;
  };

  hasFeature = containerCfg: containerCfg.copr.enable;
}
