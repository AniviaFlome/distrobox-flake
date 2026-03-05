let
  lib = import (
    fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz" + "/lib"
  );
  symlinks = {
    "/etc/`date`" = "/var/host/etc/localtime";
    "/usr/bin/\"custom\"-script" = /home/user/scripts/custom-script.sh;
  };
  linkFilesHook =
    symlinks:
    lib.mapAttrsToList (
      target: source:
      ''sudo mkdir -p "$(dirname ${lib.escapeShellArg target})" && sudo ln -sf ${lib.escapeShellArg source} ${lib.escapeShellArg target}''
    ) symlinks;
in
linkFilesHook symlinks
