# Distrobox Home Manager Module

A declarative [Home Manager](https://github.com/nix-community/home-manager) module for managing [distrobox](https://github.com/89luca89/distrobox) containers with automatic package installation.

## Installation

### Using Flakes

Add this flake to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    distrobox-flake.url = "github:AniviaFlome/distrobox-flake";
  };
}
```

## Usage

### Simple Usage

The simplest way to use this module:

```nix
{
  imports = [ inputs.distrobox.homeManagerModules.default ];

  programs.distrobox-flake = {
    enable = true;
    containers = {
      fedora = {
        distro = "fedora";
        image = "quay.io/fedora/fedora-toolbox:rawhide";
        packages = [
          "vim"
          "git"
          "neovim"
          "htop"
        ];
      };
    };
  };
}
```

## Configuration Options

### Container Options

Each container accepts the following options:

| Option            | Type            | Default        | Description                                                                             |
| ----------------- | --------------- | -------------- | --------------------------------------------------------------------------------------- |
| `name`            | string          | attribute name | Name of the container                                                                   |
| `distro`          | enum            | required       | Distribution type: `arch`, `ubuntu`, `debian`, `fedora`, `centos`, `opensuse`, `alpine` |
| `image`           | string          | required       | Container image (e.g., `archlinux:latest`)                                              |
| `packages`        | list of strings | `[]`           | Packages to install                                                                     |
| `aurPackages`     | list of strings | `[]`           | AUR packages to install (Arch only, uses paru)                                          |
| `coprRepos`       | list of strings | `[]`           | COPR repos to enable (Fedora only)                                                      |
| `autoUpdate`      | bool            | `false`        | Update container on each rebuild                                                        |
| `preInstall`      | lines           | `""`           | Commands to run before package installation                                             |
| `postInstall`     | lines           | `""`           | Commands to run after package installation                                              |
| `initHook`        | lines           | `""`           | Commands to run during container initialization                                         |
| `additionalFlags` | list of strings | `[]`           | Extra flags for `distrobox create`                                                      |

### Supported Distributions

The module supports the following distributions:

- **arch** → `pacman`
- **ubuntu** → `apt`
- **debian** → `apt`
- **fedora** → `dnf`
- **opensuse** → `zypper`
- **alpine** → `apk`

**Important:** You must specify the `distro` option for each container. If you specify an unsupported distro, home-manager will fail to switch with an error message.

## How It Works

1. **Container Creation**: On `home-manager switch`, the module checks if each declared container exists
2. **Auto-Update** (optional): If `autoUpdate = true`, updates the container using the package manager
3. **Init Hooks**: Runs initialization commands if specified
4. **COPR Setup**: Enables COPR repositories for Fedora containers
5. **Package Installation**: Installs regular packages without system update
6. **AUR Installation**: For Arch Linux, installs AUR helper (if needed) and AUR packages
7. **Hooks Execution**: Pre-install and post-install hooks are executed at the appropriate times
8. **Idempotency**: The module is designed to be idempotent - you can run it multiple times safely

### Important Notes

- **No system updates during package installation**: The module does NOT run system updates (like `pacman -Syu`) when installing packages. Use `autoUpdate = true` if you want containers updated on each rebuild.
- **AUR helper**: paru is automatically installed if not present when `aurPackages` is specified.
- **COPR repos**: COPR repositories are enabled before installing packages, so you can install packages from those repos in the `packages` list.
- **Distro validation**: The module uses assertions to prevent home-manager from switching if you specify an unsupported distro.

## Tips

### Accessing Containers

After setup, access your containers with:

```bash
distrobox enter arch
distrobox enter ubuntu
```

### Listing Containers

```bash
distrobox list
```

### Stopping/Removing Containers

```bash
distrobox stop arch
distrobox rm arch
```

### Exporting Applications

You can export applications from containers to your host:

```bash
distrobox enter arch
distrobox-export --app firefox
```

## Development

This project includes development tooling for contributors:

### Development Shell

Enter the development environment with all necessary tools:

```bash
nix-shell
```

This provides:

- `nixpkgs-fmt` - Nix code formatter
- `nil` - Nix LSP server
- `treefmt` - Multi-language formatter
- `distrobox` and `podman` - For testing

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.
