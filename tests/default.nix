{ lib }:

let
  coprTests = import ./test_copr_pure.nix { inherit lib; };
in
coprTests
