{ pkgs }:

{
  test-default = import ./default_integration.nix { inherit pkgs; };
  test-aur = import ./aur.nix { inherit pkgs; };
  test-packages = import ./packages.nix { inherit pkgs; };
  test-chaotic-aur = import ./chaotic_aur.nix { inherit pkgs; };
  test-symlinks = import ./symlinks.nix { inherit pkgs; };
  test-copr = import ./copr_integration.nix { inherit pkgs; };
  test-rpmfusion = import ./rpmfusion.nix { inherit pkgs; };
  test-copr-pure = import ./copr_pure.nix { inherit pkgs; };
}
