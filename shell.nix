{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "distrobox-flake-dev";

  buildInputs = with pkgs; [
    treefmt
    distrobox
    podman
  ];

  shellHook = ''
    echo "🚀 Distrobox Flake Development Environment"
    echo ""
    echo "Available commands:"
    echo "  nix flake check    - Run flake checks"
    echo "  nixpkgs-fmt .      - Format Nix files"
    echo "  treefmt            - Format all files"
    echo ""
    echo "📦 Distrobox version: $(distrobox version 2>/dev/null || echo 'not installed')"
    echo ""
  '';
}
