{ lib }:

let
  coprTests = import ./copr.nix { inherit lib; };
in
coprTests
