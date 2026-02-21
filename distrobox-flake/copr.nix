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
  config.programs.distrobox.containers = mapAttrs (_: c: {
    pre_init_hooks = coprPreHooks c.copr.repos;
    init_hooks = coprInstallHook c.copr.packages;
  }) containersWithCopr;
}
