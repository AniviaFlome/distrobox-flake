{ lib }:

let
  linkPackagesHook =
    packages:
    map (
      pkg:
      ''[ ! -d "${pkg}/bin" ] || sudo find "${pkg}/bin" -mindepth 1 -maxdepth 1 \( -type f -executable -o -type l \) -exec sudo ln -sf {} /usr/local/bin/ \;''
    ) packages;

  linkAllPackagesHook = ''[ ! -d "$HOME/.nix-profile/bin" ] || sudo find "$HOME/.nix-profile/bin" -mindepth 1 -maxdepth 1 \( -type f -executable -o -type l \) -exec sudo ln -sf {} /usr/local/bin/ \;'';
in
{
  options = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Nix packages to symlink into the container. The contents of their `bin/` directories will be symlinked to `/usr/local/bin/` inside the container.";
    };

    allPackages.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Symlink all packages from the user's Nix profile (`~/.nix-profile/bin`) into the container.";
    };
  };

  mkContainerConfig = containerCfg: {
    init_hooks =
      linkPackagesHook containerCfg.packages
      ++ lib.optional containerCfg.allPackages.enable linkAllPackagesHook;
  };

  hasFeature = containerCfg: containerCfg.packages != [ ] || containerCfg.allPackages.enable;
}
