{ lib }:

with lib;

let
  linkPackagesHook =
    packages:
    map (
      pkg:
      ''[ ! -d "${pkg}/bin" ] || sudo find "${pkg}/bin" -mindepth 1 -maxdepth 1 \( -type f -executable -o -type l \) -exec sudo ln -sf {} /usr/local/bin/ \;''
    ) packages;
in
{
  options.packages = mkOption {
    type = types.listOf types.package;
    default = [ ];
    description = "Nix packages to symlink into the container. The contents of their `bin/` directories will be symlinked to `/usr/local/bin/` inside the container.";
  };

  mkContainerConfig = containerCfg: {
    init_hooks = linkPackagesHook containerCfg.packages;
  };

  hasFeature = containerCfg: containerCfg.packages != [ ];
}
