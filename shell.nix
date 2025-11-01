{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "distrobox-flake-dev";

  buildInputs = with pkgs; [
    # Nix development tools
    nixpkgs-fmt
    nil # Nix LSP
    
    # Code formatting
    treefmt
    shfmt
    nodePackages.prettier
    
    # Testing and utilities
    distrobox
    podman
    
    # Documentation
    mdbook
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
