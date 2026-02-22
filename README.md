# distrobox-extra

Extension module for [home-manager](https://github.com/nix-community/home-manager)'s `programs.distrobox` that adds distro-specific features via `distrobox-assemble` hooks.

## Features

- **AUR packages** (Arch) — auto-bootstraps [paru](https://github.com/Morganamilo/paru) and installs AUR packages
- **Chaotic AUR** (Arch) — sets up the [Chaotic AUR](https://aur.chaotic.cx/) repository and installs packages
- **COPR repos** (Fedora) — enables COPR repositories and installs packages from them
- **RPM Fusion** (Fedora) — enables free and/or nonfree RPM Fusion repositories

## Installation

Add the flake input:

```nix
# flake.nix
{
  inputs = {
    distrobox-flake.url = "github:AniviaFlome/distrobox-flake";
  };
}
```

## Example Config

```nix
{
  imports = [ inputs.distrobox-flake.homeManagerModules.default ];

  programs.distrobox = {
    enable = true;
    containers = {
      arch = {
        image = "archlinux:latest";
        additional_packages = "vim git neovim";
      };
      fedora = {
        image = "fedora:41";
        additional_packages = "gcc make starship";
      };
    };
  };

  programs.distrobox-flake.containers = {
    arch = {
      aur = {
        enable = true;
        packages = [ "visual-studio-code-bin" ];
      };
    };
    fedora = {
      copr = {
        enable = true;
        repos = [ "atim/starship" ];
        packages = [ "starship" ];
      };
      rpmfusion = {
        free = true;
        nonfree = true;
      };
    };
  };
}
```
