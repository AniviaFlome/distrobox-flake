{ config, lib, ... }:

with lib;

let
  cfg = config.programs.distrobox-extra;

  coprPreHooks = repos: map (repo: "sudo dnf copr enable -y ${repo}") repos;

  coprInstallHook =
    packages: optional (packages != [ ]) "sudo dnf install -y ${concatStringsSep " " packages}";

  containersWithCopr = filterAttrs (_: c: c.copr.enable) cfg.containers;
in
{
  options.programs.distrobox-extra.containers = mkOption {
    type = types.attrsOf (
      types.submodule {
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
      }
    );
    default = { };
  };

  config.programs.distrobox.containers = mapAttrs (_: c: {
    pre_init_hooks = coprPreHooks c.copr.repos;
    init_hooks = coprInstallHook c.copr.packages;
  }) containersWithCopr;
}
