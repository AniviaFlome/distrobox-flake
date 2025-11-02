{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.distrobox-flake;

  # Supported distributions
  supportedDistros = [
    "arch"
    "ubuntu"
    "debian"
    "fedora"
    "opensuse"
    "alpine"
  ];

  # Map distro to package manager
  distroToPackageManager = {
    arch = "pacman";
    debian = "apt";
    fedora = "dnf";
    opensuse = "zypper";
    alpine = "apk";
  };

  # Container configuration type
  containerType = types.submodule (
    { name, ... }:
    {
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
          default = [ ];
          description = "List of packages to install in the container";
          example = [
            "vim"
            "git"
            "htop"
          ];
        };

        aurPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "List of AUR packages to install (Arch Linux only, uses paru)";
          example = [
            "paru-bin"
            "visual-studio-code-bin"
          ];
        };

        coprRepos = mkOption {
          type = types.listOf types.str;
          default = [ ];
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
          default = [ ];
          description = "Additional flags to pass to distrobox create";
          example = [
            "--home"
            "$HOME/distrobox/ubuntu"
          ];
        };
      };
    }
  );

  # State directory for tracking installed packages
  stateDir = "${config.home.homeDirectory}/.local/distrobox-flake";

  # Get package manager from distro
  getPackageManager = distro: distroToPackageManager.${distro};

  # Generate update command for a package manager
  getUpdateCommand =
    pm:
    if pm == "pacman" then
      "pacman -Syu --noconfirm > /dev/null"
    else if pm == "apt" then
      "apt update && apt upgrade -y > /dev/null"
    else if pm == "dnf" then
      "dnf upgrade -y > /dev/null"
    else if pm == "zypper" then
      "zypper update -y > /dev/null"
    else if pm == "apk" then
      "apk upgrade > /dev/null"
    else
      "echo 'Unknown package manager: ${pm}'";

  # Generate install command for a package manager (without system update)
  getInstallCommand =
    pm: packages:
    let
      pkgList = concatStringsSep " " packages;
    in
    if pm == "pacman" then
      "pacman -S --noconfirm ${pkgList}"
    else if pm == "apt" then
      "apt install -y ${pkgList}"
    else if pm == "dnf" then
      "dnf install -y ${pkgList}"
    else if pm == "zypper" then
      "zypper install -y ${pkgList}"
    else if pm == "apk" then
      "apk add ${pkgList}"
    else
      "echo 'Unknown package manager: ${pm}'";

  # Generate remove command for a package manager
  getRemoveCommand =
    pm: packages:
    let
      pkgList = concatStringsSep " " packages;
    in
    if pm == "pacman" then
      "pacman -Rs --noconfirm ${pkgList}"
    else if pm == "apt" then
      "apt remove -y ${pkgList}"
    else if pm == "dnf" then
      "dnf remove -y ${pkgList}"
    else if pm == "zypper" then
      "zypper remove -y ${pkgList}"
    else if pm == "apk" then
      "apk del ${pkgList}"
    else
      "echo 'Unknown package manager: ${pm}'";

  # Generate setup script for a single container
  generateContainerScript =
    name: container:
    let
      pm = getPackageManager container.distro;
      installCmd = if container.packages != [ ] then getInstallCommand pm container.packages else "";
      updateCmd = getUpdateCommand pm;
      flags = concatStringsSep " " container.additionalFlags;

      # State files for tracking packages
      packagesStateFile = "${stateDir}/${name}-packages.txt";
      aurPackagesStateFile = "${stateDir}/${name}-aur-packages.txt";

      # Current packages as newline-separated string
      currentPackages = concatStringsSep "\n" container.packages;
      currentAurPackages = concatStringsSep "\n" container.aurPackages;

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
      aurInstallCmd =
        if container.aurPackages != [ ] then
          "paru -S --noconfirm ${concatStringsSep " " container.aurPackages}"
        else
          "";

      # COPR repo setup
      coprSetup = concatStringsSep "\n" (
        map (repo: "sudo dnf copr enable -y ${repo}") container.coprRepos
      );
    in
    pkgs.writeShellScript "distrobox-setup-${name}" ''
      set -euo pipefail

      # Ensure state directory exists
      mkdir -p "${stateDir}"

      # Check if container exists
      if ! ${pkgs.distrobox}/bin/distrobox list | grep -q "^${container.name}"; then
        ${pkgs.distrobox}/bin/distrobox create \
          --name "${container.name}" \
          --image "${container.image}" \
          ${flags} \
          --yes > /dev/null 2>&1
      fi

      # Update container if autoUpdate is enabled
      ${optionalString container.autoUpdate ''
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo bash -c '${updateCmd}' > /dev/null 2>&1
      ''}

      # Run initialization hook if provided
      ${optionalString (container.initHook != "") ''
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '${container.initHook}' > /dev/null 2>&1
      ''}

      # Enable COPR repos for Fedora
      ${optionalString (container.coprRepos != [ ] && pm == "dnf") ''
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '
          ${coprSetup}
        ' > /dev/null 2>&1
      ''}

      # Handle package removal (compare with previous state)
      if [ -f "${packagesStateFile}" ]; then
        # Get packages that were previously installed but are now removed
        REMOVED_PACKAGES=$(comm -23 \
          <(sort "${packagesStateFile}") \
          <(echo "${currentPackages}" | sort))

        if [ -n "$REMOVED_PACKAGES" ]; then
          REMOVE_CMD="${getRemoveCommand pm "$REMOVED_PACKAGES"}"
          ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo bash -c "$REMOVE_CMD" > /dev/null 2>&1 || true
        fi
      fi

      # Install regular packages if any are specified
      ${optionalString (container.packages != [ ]) ''
        # Run pre-install commands
        ${optionalString (container.preInstall != "") ''
          ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '${container.preInstall}' > /dev/null 2>&1
        ''}

        # Install packages
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo bash -c '${installCmd}' > /dev/null 2>&1

        # Run post-install commands
        ${optionalString (container.postInstall != "") ''
          ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '${container.postInstall}' > /dev/null 2>&1
        ''}
      ''}

      # Update package state file
      echo "${currentPackages}" > "${packagesStateFile}"

      # Handle AUR package removal for Arch Linux
      ${optionalString (pm == "pacman") ''
        if [ -f "${aurPackagesStateFile}" ]; then
          # Get AUR packages that were previously installed but are now removed
          REMOVED_AUR_PACKAGES=$(comm -23 \
            <(sort "${aurPackagesStateFile}") \
            <(echo "${currentAurPackages}" | sort))

          if [ -n "$REMOVED_AUR_PACKAGES" ]; then
            ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- paru -Rs --noconfirm $REMOVED_AUR_PACKAGES > /dev/null 2>&1 || true
          fi
        fi
      ''}

      # Install AUR packages for Arch Linux
      ${optionalString (container.aurPackages != [ ] && pm == "pacman") ''
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '
          ${paruInstall}
          ${aurInstallCmd}
        ' > /dev/null 2>&1
      ''}

      # Update AUR package state file
      ${optionalString (pm == "pacman") ''
        echo "${currentAurPackages}" > "${aurPackagesStateFile}"
      ''}
    '';

  # Generate main activation script
  activationScript = pkgs.writeShellScript "distrobox-activation" ''
    set -euo pipefail

    ${concatStringsSep "\n" (
      mapAttrsToList (name: container: ''
        ${generateContainerScript name container}
      '') cfg.containers
    )}
  '';

in
{
  options.programs.distrobox-flake = {
    enable = mkEnableOption "distrobox container management";

    containers = mkOption {
      type = types.attrsOf containerType;
      default = { };
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

    # Ensure distrobox and podman are available
    home.packages = [
      pkgs.distrobox
      pkgs.podman
    ];

    # Run activation script on home-manager switch
    home.activation.distrobox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${pkgs.podman}/bin:${pkgs.distrobox}/bin:${pkgs.gawk}/bin:${pkgs.gnused}/bin:${pkgs.gnugrep}/bin:${pkgs.util-linux}/bin:$PATH"
      ${activationScript} > /dev/null
    '';
  };
}
