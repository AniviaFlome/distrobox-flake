{ lib }:

let
  coprTests = import ./copr_pure.nix { inherit lib; };
in
coprTests
