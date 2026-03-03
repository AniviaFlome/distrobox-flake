{ lib }:

with lib;

let
  linkFilesHook =
    symlinks:
    mapAttrsToList (target: source: ''sudo mkdir -p "$(dirname "${target}")" && sudo ln -sf "${source}" "${target}"'') symlinks;
in
{
  options.symlinks = mkOption {
    type = types.attrsOf (types.either types.path types.str);
    default = { };
    description = "A mapping of target path in the container to source path. The source path will be symlinked to the target path inside the container.";
    example = {
      "/etc/localtime" = "/var/host/etc/localtime";
      "/usr/bin/custom-script" = "/home/user/scripts/custom-script.sh";
    };
  };

  mkContainerConfig = containerCfg: {
    init_hooks = linkFilesHook containerCfg.symlinks;
  };

  hasFeature = containerCfg: containerCfg.symlinks != { };
}
