{
  lib ?
    import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz")
      { }.lib,
}:

let
  dummyModule = {
    options = { };
    config = { };
  };
in
lib.evalModules { modules = [ dummyModule ]; }
