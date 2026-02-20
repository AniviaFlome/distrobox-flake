# distrobox-extra

Extension module for [home-manager](https://github.com/nix-community/home-manager)'s `programs.distrobox` that adds distro-specific features via `distrobox-assemble` hooks.

## Features

- **AUR packages** (Arch) — auto-bootstraps [paru](https://github.com/Morganamilo/paru) and installs AUR packages
- **COPR repos** (Fedora) — enables COPR repositories before package installation
- **RPM Fusion** (Fedora) — enables free and/or nonfree RPM Fusion repositories

## How It Works

Each sub-module compiles its options into `pre_init_hooks` or `init_hooks` that get merged into `programs.distrobox.containers`, which home-manager renders into the `distrobox-assemble` INI file.

## Example Config

```nix
{
  imports = [ ./distrobox-extra ];

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

  programs.distrobox-extra.containers = {
    arch = {
      enable = true;
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
