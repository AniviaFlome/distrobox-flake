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

        fedora = mkOption {
          type = types.submodule {
            options = {
              rpmfusion = {
                enable = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Enable RPM Fusion repositories (free and nonfree) for Fedora containers";
                };
              };
            };
          };
          default = { };
          description = "Fedora-specific options";
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
  stateDir = "${config.home.homeDirectory}/.local/state/distrobox-flake";

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
      "pacman -S --needed --noconfirm ${pkgList}"
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

      # State files for tracking packages and image
      packagesStateFile = "${stateDir}/${name}-packages.txt";
      aurPackagesStateFile = "${stateDir}/${name}-aur-packages.txt";
      imageStateFile = "${stateDir}/${name}-image.txt";
      coprReposStateFile = "${stateDir}/${name}-copr-repos.txt";
      rpmfusionStateFile = "${stateDir}/${name}-rpmfusion.txt";


      # Current packages as newline-separated string
      currentPackages = concatStringsSep "\n" container.packages;
      currentAurPackages = concatStringsSep "\n" container.aurPackages;
      currentCoprRepos = concatStringsSep "\n" container.coprRepos;
      currentRpmfusion = if container.fedora.rpmfusion.enable then "enabled" else "disabled";

      # Paru AUR helper installation script
      paruInstall = ''
        if ! command -v paru &> /dev/null; then
          echo "==> Installing paru AUR helper"
          sudo pacman -S --needed --noconfirm base-devel git
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
          "paru -S --needed --noconfirm ${concatStringsSep " " container.aurPackages}"
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

      # Check if container exists and get its current image
      CONTAINER_EXISTS=false
      CURRENT_IMAGE=""
      # Parse distrobox list with pipe separator, skip header, trim whitespace
      CONTAINER_INFO=$(${pkgs.distrobox}/bin/distrobox list --no-color 2>/dev/null | ${pkgs.gawk}/bin/awk -F'|' -v name="${container.name}" '
        NR>1 {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2);
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4);
          if ($2 == name) {
            print $4;
            exit;
          }
        }
      ' || echo "")
      
      if [ -n "$CONTAINER_INFO" ]; then
        CONTAINER_EXISTS=true
        CURRENT_IMAGE="$CONTAINER_INFO"
      fi

      # Check if image has changed by comparing actual container image with configured image
      IMAGE_CHANGED=false
      if [ "$CONTAINER_EXISTS" = true ] && [ -n "$CURRENT_IMAGE" ]; then
        if [ "$CURRENT_IMAGE" != "${container.image}" ]; then
          echo "==> Image mismatch for ${container.name}: $CURRENT_IMAGE -> ${container.image}"
          IMAGE_CHANGED=true
        fi
      fi

      # Remove and recreate container if image changed
      if [ "$CONTAINER_EXISTS" = true ] && [ "$IMAGE_CHANGED" = true ]; then
        echo "==> Rebuilding container ${container.name} due to image change"
        ${pkgs.distrobox}/bin/distrobox rm "${container.name}" --force
        CONTAINER_EXISTS=false
      fi

      # Create container if it doesn't exist
      if [ "$CONTAINER_EXISTS" = false ]; then
        echo "==> Creating container ${container.name}"
        ${pkgs.distrobox}/bin/distrobox create \
          --name "${container.name}" \
          --image "${container.image}" \
          ${flags} \
          --yes
        # Clear state files when container is recreated
        rm -f "${packagesStateFile}" "${aurPackagesStateFile}"
      fi

      # Update image state file
      echo "${container.image}" > "${imageStateFile}"

      # Update container if autoUpdate is enabled
      ${optionalString container.autoUpdate ''
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo bash -c '${updateCmd}'
      ''}

      # Run initialization hook if provided
      ${optionalString (container.initHook != "") ''
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '${container.initHook}'
      ''}

      # Handle RPM Fusion for Fedora
      ${optionalString (pm == "dnf") ''
      # Check previous RPM Fusion state
      PREV_RPMFUSION="disabled"
      if [ -f "${rpmfusionStateFile}" ]; then
      PREV_RPMFUSION=$(cat "${rpmfusionStateFile}")
      fi
      # Enable RPM Fusion if requested
      if [ "${currentRpmfusion}" = "enabled" ] && [ "$PREV_RPMFUSION" != "enabled" ]; then
      echo "==> Enabling RPM Fusion repositories"
      ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo bash -c '
      dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
      dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
      '
      fi
      # Disable RPM Fusion if no longer requested
      if [ "${currentRpmfusion}" = "disabled" ] && [ "$PREV_RPMFUSION" = "enabled" ]; then
      echo "==> Removing RPM Fusion repositories"
      ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo bash -c '
      dnf remove -y rpmfusion-free-release rpmfusion-nonfree-release || true
      '
      fi
      # Update RPM Fusion state file
      echo "${currentRpmfusion}" > "${rpmfusionStateFile}"
      ''}
      # Handle COPR repo removal for Fedora
      ${optionalString (pm == "dnf") ''
      if [ -f "${coprReposStateFile}" ]; then
      # Get COPR repos that were previously enabled but are now removed
      REMOVED_COPR_REPOS=$(comm -23 \
      <(sort "${coprReposStateFile}") \
      <(echo "${currentCoprRepos}" | sort))
      if [ -n "$REMOVED_COPR_REPOS" ]; then
      echo "==> Removing COPR repositories no longer in config"
      for repo in $REMOVED_COPR_REPOS; do
      if [ -n "$repo" ]; then
      echo " Disabling COPR repo: $repo"
      ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo dnf copr disable -y "$repo" || true
      fi
      done
      fi
      fi
      ''}

      # Enable COPR repos for Fedora
      ${optionalString (container.coprRepos != [ ] && pm == "dnf") ''
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '
          ${coprSetup}
        '
      ''}

      # Handle package removal (compare with previous state)
      if [ -f "${packagesStateFile}" ]; then
        # Get packages that were previously installed but are now removed
        REMOVED_PACKAGES=$(comm -23 \
          <(sort "${packagesStateFile}") \
          <(echo "${currentPackages}" | sort))

        if [ -n "$REMOVED_PACKAGES" ]; then
          ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo bash -c "${
            if pm == "pacman" then
              "pacman -Rs --noconfirm"
            else if pm == "apt" then
              "apt remove -y"
            else if pm == "dnf" then
              "dnf remove -y"
            else if pm == "zypper" then
              "zypper remove -y"
            else if pm == "apk" then
              "apk del"
            else
              "echo 'Unknown package manager'"
          } $REMOVED_PACKAGES" || true
        fi
      fi

      # Install regular packages if any are specified
      ${optionalString (container.packages != [ ]) ''
        # Run pre-install commands
        ${optionalString (container.preInstall != "") ''
          ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '${container.preInstall}'
        ''}

        # Install packages
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- sudo bash -c '${installCmd}'

        # Run post-install commands
        ${optionalString (container.postInstall != "") ''
          ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '${container.postInstall}'
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
            ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- paru -Rs --noconfirm $REMOVED_AUR_PACKAGES || true
          fi
        fi
      ''}

      # Install AUR packages for Arch Linux
      ${optionalString (container.aurPackages != [ ] && pm == "pacman") ''
        ${pkgs.distrobox}/bin/distrobox enter "${container.name}" -- bash -c '
          ${paruInstall}
          ${aurInstallCmd}
        '
      ''}

      # Update AUR package state file
      ${optionalString (pm == "pacman") ''
        echo "${currentAurPackages}" > "${aurPackagesStateFile}"
      ''}
    '';

  # Generate main activation script
  activationScript = pkgs.writeShellScript "distrobox-activation" ''
    set -euo pipefail

    # List of containers that should exist (defined in config)
    CONFIGURED_CONTAINERS=(${concatStringsSep " " (mapAttrsToList (name: _: name) cfg.containers)})

    # Get list of existing distrobox containers
    if command -v ${pkgs.distrobox}/bin/distrobox &> /dev/null; then
      EXISTING_CONTAINERS=$(${pkgs.distrobox}/bin/distrobox list --no-color 2>/dev/null | ${pkgs.gawk}/bin/awk -F'|' 'NR>1 {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}' || true)

      # Remove containers not in config
      for container in $EXISTING_CONTAINERS; do
        FOUND=false
        for configured in "''${CONFIGURED_CONTAINERS[@]}"; do
          if [ "$container" = "$configured" ]; then
            FOUND=true
            break
          fi
        done

        if [ "$FOUND" = false ]; then
          echo "==> Removing container '$container' (not in configuration)"
          ${pkgs.distrobox}/bin/distrobox rm "$container" --force
          # Clean up state files for removed container
          rm -f "${stateDir}/$container-packages.txt"
          rm -f "${stateDir}/$container-aur-packages.txt"
          rm -f "${stateDir}/$container-image.txt"
          rm -f "${stateDir}/$container-copr-repos.txt"
          rm -f "${stateDir}/$container-rpmfusion.txt"
        fi
      done
    fi

    # Setup configured containers
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
            rpmfusion.enable = true;
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
