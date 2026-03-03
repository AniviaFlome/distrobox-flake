{ lib }:

with lib;

let
  linkPackagesHook =
    packages:
    let
      # For each package, create a string of shell commands to symlink its bin/
      # contents to /usr/local/bin/. We use find to easily locate executables.
      linkCmds = map (pkg: ''
        if [ -d "${pkg}/bin" ]; then
          sudo find "${pkg}/bin" -mindepth 1 -maxdepth 1 -type f -executable -o -type l | while read -r f; do
            sudo ln -sf "$f" "/usr/local/bin/"
          done
        fi
      '') packages;
    in
    optional (packages != [ ]) (concatStringsSep "\n" linkCmds);
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
