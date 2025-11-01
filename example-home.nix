_:

{
  # Example 1: Simple Arch container with packages
  programs.distrobox = {
    enable = true;

    containers = {
      arch = {
        distro = "arch";
        image = "archlinux:latest";
        packages = [
          "vim"
          "git"
          "neovim"
          "htop"
        ];
      };
    };
  };

  # Example 2: Arch container with AUR packages
  # programs.distrobox = {
  #   enable = true;
  #
  #   containers = {
  #     arch-dev = {
  #       distro = "arch";
  #       image = "archlinux:latest";
  #       packages = [ "base-devel" "git" "neovim" "python" "nodejs" ];
  #
  #       # AUR packages support (uses paru)
  #       aurPackages = [ "paru-bin" "visual-studio-code-bin" "spotify" ];
  #
  #       # Auto-update on rebuild
  #       autoUpdate = true;
  #
  #       preInstall = ''
  #         echo "Preparing system..."
  #       '';
  #       postInstall = ''
  #         echo "Setup complete!"
  #       '';
  #     };
  #   };
  # };

  # Example 3: Fedora container with COPR repos
  # programs.distrobox = {
  #   enable = true;
  #
  #   containers = {
  #     fedora-dev = {
  #       distro = "fedora";
  #       image = "fedora:39";
  #       packages = [ "gcc" "make" "cmake" "starship" ];
  #
  #       # COPR repositories support
  #       coprRepos = [ "atim/starship" ];
  #
  #       autoUpdate = true;
  #
  #       initHook = ''
  #         echo "Fedora container initialized"
  #       '';
  #     };
  #   };
  # };

  # Example 4: Multiple containers with different configs
  # programs.distrobox = {
  #   enable = true;
  #
  #   containers = {
  #     arch = {
  #       distro = "arch";
  #       image = "archlinux:latest";
  #       packages = [ "vim" "tmux" ];
  #       aurPackages = [ "paru-bin" ];
  #       autoUpdate = false;
  #     };
  #
  #     ubuntu = {
  #       distro = "ubuntu";
  #       image = "ubuntu:22.04";
  #       packages = [ "build-essential" "curl" ];
  #       autoUpdate = true;
  #     };
  #
  #     fedora = {
  #       distro = "fedora";
  #       image = "fedora:latest";
  #       packages = [ "dnf-plugins-core" ];
  #       coprRepos = [ "some/repo" ];
  #       autoUpdate = true;
  #     };
  #   };
  # };

  home.stateVersion = "24.05";
}
