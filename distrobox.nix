{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.distrobox-flake;

  # Supported distributions
  supportedDistros = [ "arch" "ubuntu" "debian" "fedora" "opensuse" "alpine" ];

  # Map distro to package manager
  distroToPackageManager = {
    arch = "pacman";
    ubuntu = "apt";
    debian = "apt";
    fedora = "dnf";
    opensuse = "zypper";
    alpine = "apk";
  };

  # Container configuration type
  containerType = types.submodule ({ name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
        description = "Name of the distrobox container";
      };

      distro = mkOption {
        type = types.enum supportedDistros;
        description = "Distribution type for the container";
        example = "arch";
      };

      image = mkOption {
        type = types.str;
        description = "Container image to use (e.g., 'archlinux:latest', 'ubuntu:22.04')";
      };

      packages = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of packages to install in the container";
        example = [ "vim" "git" "htop" ];
      };

      aurPackages = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of AUR packages to install (Arch Linux only, uses paru)";
        example = [ "paru-bin" "visual-studio-code-bin" ];
      };

      coprRepos = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of COPR repositories to enable (Fedora only)";
        example = [ "atim/starship" ];
      };

      autoUpdate = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to update the container on each rebuild";
      };

      preInstall = mkOption {
        type = types.lines;
        default = "";
        description = "Commands to run before installing packages";
      };

      postInstall = mkOption {
        type = types.lines;
        default = "";
        description = "Commands to run after installing packages";
      };

      initHook = mkOption {
        type = types.lines;
        default = "";
        description = "Additional initialization commands";
      };

      additionalFlags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional flags to pass to distrobox create";
        example = [ "--home" "$HOME/distrobox/ubuntu" ];
      };
    };
  });

  # Get package manager from distro
  getPackageManager = distro: distroToPackageManager.${distro};

  # Generate update command for a package manager
  getUpdateCommand = pm:
    if pm == "pacman" then "pacman -Syu --noconfirm"
    else if pm == "apt" then "apt-get update && apt-get upgrade -y"
    else if pm == "dnf" then "dnf upgrade -y"
    else if pm == "zypper" then "zypper update -y"
    else if pm == "apk" then "apk upgrade"
    else "echo 'Unknown package manager: ${pm}'";

  # Generate install command for a package manager (without system update)
  getInstallCommand = pm: packages:
    let
      pkgList = concatStringsSep " " packages;
    in
      if pm == "pacman" then "pacman -S --noconfirm ${pkgList}"
      else if pm == "apt" then "apt install -y ${pkgList}"
      else if pm == "dnf" then "dnf install -y ${pkgList}"
      else if pm == "zypper" then "zypper install -y ${pkgList}"
      else if pm == "apk" then "apk add ${pkgList}"
      else "echo 'Unknown package manager: ${pm}'";

  # Generate setup script for a single container
  generateContainerScript = name: container:
    let
      pm = getPackageManager container.distro;
      installCmd = if container.packages != [] 
                   then getInstallCommand pm container.packages 
                   else "";
      updateCmd = getUpdateCommand pm;
      flags = concatStringsSep " " container.additionalFlags;
      
      # Paru AUR helper installation script
      paruInstall = ''
        if ! command -v paru &> /dev/null; then
          echo "==> Installing paru AUR helper"
          sudo pacman -S --noconfirm --needed base-devel git
          cd /tmp
          git clone https://aur.archlinux.org/paru.git
          cd paru
          makepkg -si --noconfirm
          cd ..
          rm -rf paru
        fi
      '';
      
      # AUR packages installation
      aurInstallCmd = if container.aurPackages != [] then
        "paru -S --noconfirm ${concatStringsSep " " container.aurPackages}"
      else "";
      
      # COPR repo setup
      coprSetup = concatStringsSep "\n" (map (repo: 
        "sudo dnf copr enable -y ${repo}"
      ) container.coprRepos);
    in
    pkgs.writeShellScript "distrobox-setup-${name}" ''
      set -euo pipefail

      echo "==> Setting up distrobox container: ${container.name}"

      # Check if container exists
      if ! ${pkgs.distrobox}/bin/distrobox list | grep -q "^${container.name}"; then
        echo "==> Creating container ${container.name} with image ${container.image}"
        ${pkgs.distrobox}/bin/distrobox create \
          --name "${container.name}" \
          --image "${container.image}" \
          ${flags} \
          --yes
      else
        echo "==> Container ${container.name} already exists"
      fi

      # Update container if autoUpdate is enabled
      ${optionalString container.autoUpdate ''
        echo "==> Updating container ${container.name}"
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo bash -c '${updateCmd}'
      ''}

      # Run initialization hook if provided
      ${optionalString (container.initHook != "") ''
        echo "==> Running init hook for ${container.name}"
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '${container.initHook}'
      ''}

      # Enable COPR repos for Fedora
      ${optionalString (container.coprRepos != [] && pm == "dnf") ''
        echo "==> Enabling COPR repositories: ${concatStringsSep ", " container.coprRepos}"
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '
          ${coprSetup}
        '
      ''}

      # Install regular packages if any are specified
      ${optionalString (container.packages != []) ''
        echo "==> Installing packages in ${container.name}: ${concatStringsSep ", " container.packages}"
        
        # Run pre-install commands
        ${optionalString (container.preInstall != "") ''
          echo "==> Running pre-install commands"
          ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '${container.preInstall}'
        ''}

        # Install packages
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo bash -c '${installCmd}'

        # Run post-install commands
        ${optionalString (container.postInstall != "") ''
          echo "==> Running post-install commands"
          ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '${container.postInstall}'
        ''}
      ''}

      # Install AUR packages for Arch Linux
      ${optionalString (container.aurPackages != [] && pm == "pacman") ''
        echo "==> Installing AUR packages: ${concatStringsSep ", " container.aurPackages}"
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '
          ${paruInstall}
          ${aurInstallCmd}
        '
      ''}

      echo "==> Container ${container.name} setup complete"
    '';

  # Generate main activation script
  activationScript = pkgs.writeShellScript "distrobox-activation" ''
    set -euo pipefail
    
    echo "==> Starting distrobox container setup"
    
    ${concatStringsSep "\n" (mapAttrsToList (name: container: ''
      ${generateContainerScript name container}
    '') cfg.containers)}
    
    echo "==> All distrobox containers configured"
  '';

in
{
  options.programs.distrobox-flake = {
    enable = mkEnableOption "distrobox container management";

    containers = mkOption {
      type = types.attrsOf containerType;
      default = {};
      description = "Distrobox containers to manage";
      example = literalExpression ''
        {
          arch = {
            distro = "arch";
            image = "archlinux:latest";
            packages = [ "vim" "git" "neovim" ];
            aurPackages = [ "paru-bin" ];
          };
          ubuntu = {
            distro = "ubuntu";
            image = "ubuntu:22.04";
            packages = [ "curl" "wget" ];
            autoUpdate = true;
          };
          fedora = {
            distro = "fedora";
            image = "fedora:39";
            packages = [ "gcc" "make" ];
            coprRepos = [ "atim/starship" ];
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Assertions to prevent home-manager switch with invalid config
    assertions = mapAttrsToList (name: container: {
      assertion = elem container.distro supportedDistros;
      message = "Container '${name}' has unsupported distro '${container.distro}'. Supported distros: ${concatStringsSep ", " supportedDistros}";
    }) cfg.containers;

    # Ensure distrobox is available
    home.packages = [ pkgs.distrobox ];

    # Run activation script on home-manager switch
    home.activation.distrobox = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${activationScript}
    '';
  };
}
