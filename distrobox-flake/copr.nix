{ lib }:

let
  coprPreHooks = repos: map (repo: "sudo dnf copr enable -y ${lib.escapeShellArg repo}") repos;

  coprInstallHook =
    packages: lib.optional (packages != [ ]) "sudo dnf install -y ${lib.escapeShellArgs packages}";
in
{
  options.copr = {
    enable = lib.mkEnableOption "COPR repository support (Fedora containers only)";

    repos = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "COPR repositories to enable. Enabled before package installation.";
      example = [ "atim/starship" ];
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Packages to install from COPR repositories.";
      example = [ "starship" ];
    };
  };

  mkContainerConfig = containerCfg: {
    pre_init_hooks = coprPreHooks containerCfg.copr.repos;
    init_hooks = coprInstallHook containerCfg.copr.packages;
  };

  hasFeature =
    containerCfg:
    containerCfg.copr.enable && (containerCfg.copr.repos != [ ] || containerCfg.copr.packages != [ ]);
}
