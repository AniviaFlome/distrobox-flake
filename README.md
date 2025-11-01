# Distrobox Home Manager Module

A declarative [Home Manager](https://github.com/nix-community/home-manager) module for managing [distrobox](https://github.com/89luca89/distrobox) containers with automatic package installation.

## Features

- 🚀 **Declarative container management** - Define containers and packages in Nix
- 📦 **Auto package installation** - Automatically installs packages using the appropriate package manager
- 🎯 **Multiple distro support** - Works with Arch, Ubuntu, Debian, Fedora, CentOS, openSUSE, and Alpine
- 🛠️ **Flexible hooks** - Pre/post install hooks and initialization scripts
- 🔧 **AUR support** - Install AUR packages with paru (Arch Linux)
- 📚 **COPR support** - Enable and use COPR repositories (Fedora)
- ♻️ **Auto-update option** - Optionally update containers on each rebuild
- ⚠️ **Strict validation** - Prevents home-manager switch with invalid distro configuration

## Installation

### Using Flakes

Add this flake to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    distrobox-flake.url = "path:/path/to/distrobox-flake";
  };

  outputs = { nixpkgs, home-manager, distrobox-flake, ... }: {
    homeConfigurations.youruser = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        distrobox-flake.homeManagerModules.distrobox
        ./home.nix
      ];
    };
  };
}
```

### Without Flakes

Import the module directly in your Home Manager configuration:

```nix
{ config, pkgs, ... }:

{
  imports = [
    /path/to/distrobox-flake/distrobox.nix
  ];
  
  # ... rest of configuration
}
```

## Usage

### Simple Usage

The simplest way to use this module:

```nix
programs.distrobox = {
  enable = true;
  
  containers = {
    arch = {
      distro = "arch";
      image = "archlinux:latest";
      packages = [ "vim" "git" "neovim" ];
    };
  };
};
```

This creates an Arch Linux container named "arch" and installs the specified packages.

### Multiple Containers

You can define multiple containers:

```nix
programs.distrobox = {
  enable = true;
  
  containers = {
    arch = {
      distro = "arch";
      image = "archlinux:latest";
      packages = [ "vim" "tmux" "htop" ];
    };
    
    ubuntu = {
      distro = "ubuntu";
      image = "ubuntu:22.04";
      packages = [ "build-essential" "curl" ];
      autoUpdate = true;
    };
    
    fedora = {
      distro = "fedora";
      image = "fedora:39";
      packages = [ "gcc" "make" ];
    };
  };
};
```

### Advanced Configuration

```nix
programs.distrobox = {
  enable = true;
  
  containers = {
    arch-dev = {
      distro = "arch";
      image = "archlinux:latest";
      packages = [ "base-devel" "git" "neovim" "python" "nodejs" ];
      
      # Install AUR packages (uses paru)
      aurPackages = [ "visual-studio-code-bin" "spotify" "paru-bin" ];
      
      # Update container on each rebuild
      autoUpdate = true;
      
      preInstall = ''
        echo "Setting up..."
      '';
      
      postInstall = ''
        echo "Setup complete!"
      '';
      
      initHook = ''
        echo "Arch development container ready!"
      '';
    };
    
    fedora-server = {
      distro = "fedora";
      image = "fedora:39";
      packages = [ "nginx" "postgresql" "starship" ];
      
      # Enable COPR repositories
      coprRepos = [ "atim/starship" ];
      
      autoUpdate = true;
      
      additionalFlags = [ "--home" "$HOME/distrobox/fedora" ];
    };
  };
};
```

### AUR Packages (Arch Linux)

For Arch Linux containers, you can install AUR packages:

```nix
programs.distrobox.containers.arch = {
  distro = "arch";
  image = "archlinux:latest";
  packages = [ "base-devel" "git" ];
  
  # AUR packages (uses paru)
  aurPackages = [ 
    "paru-bin"
    "visual-studio-code-bin"
    "spotify"
    "google-chrome"
  ];
};
```

The module will automatically install paru if not present.

### COPR Repositories (Fedora)

For Fedora containers, you can enable COPR repositories:

```nix
programs.distrobox.containers.fedora = {
  distro = "fedora";
  image = "fedora:39";
  
  # Enable COPR repos before installing packages
  coprRepos = [
    "atim/starship"
    "evana/fzf-extras"
  ];
  
  packages = [ "starship" "fzf" ];
};
```

COPR repositories are enabled before package installation.

## Configuration Options

### Container Options

Each container accepts the following options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | attribute name | Name of the container |
| `distro` | enum | required | Distribution type: `arch`, `ubuntu`, `debian`, `fedora`, `centos`, `opensuse`, `alpine` |
| `image` | string | required | Container image (e.g., `archlinux:latest`) |
| `packages` | list of strings | `[]` | Packages to install |
| `aurPackages` | list of strings | `[]` | AUR packages to install (Arch only, uses paru) |
| `coprRepos` | list of strings | `[]` | COPR repos to enable (Fedora only) |
| `autoUpdate` | bool | `false` | Update container on each rebuild |
| `preInstall` | lines | `""` | Commands to run before package installation |
| `postInstall` | lines | `""` | Commands to run after package installation |
| `initHook` | lines | `""` | Commands to run during container initialization |
| `additionalFlags` | list of strings | `[]` | Extra flags for `distrobox create` |

### Supported Distributions

The module supports the following distributions:

- **arch** → `pacman`
- **ubuntu** → `apt`
- **debian** → `apt`
- **fedora** → `dnf`
- **centos** → `dnf`
- **opensuse** → `zypper`
- **alpine** → `apk`

**Important:** You must specify the `distro` option for each container. If you specify an unsupported distro, home-manager will fail to switch with an error message.

## Examples

### Development Environment with AUR

```nix
programs.distrobox.containers.devenv = {
  distro = "arch";
  image = "archlinux:latest";
  
  packages = [
    "base-devel"
    "git"
    "neovim"
    "python"
    "nodejs"
    "rust"
    "go"
  ];
  
  # Install tools from AUR (uses paru)
  aurPackages = [
    "visual-studio-code-bin"
    "postman-bin"
    "docker-desktop"
  ];
  
  autoUpdate = true;
  
  postInstall = ''
    # Additional setup
    echo "Development environment ready!"
  '';
};
```

### Fedora Server with COPR

```nix
programs.distrobox.containers.webserver = {
  distro = "fedora";
  image = "fedora:39";
  
  # Enable COPR repos
  coprRepos = [
    "atim/starship"
  ];
  
  packages = [ "nginx" "postgresql" "redis" "starship" ];
  
  autoUpdate = true;
  
  initHook = ''
    echo "Web server container initialized"
  '';
};
```

### Gaming Setup

```nix
programs.distrobox.containers.gaming = {
  distro = "arch";
  image = "archlinux:latest";
  
  packages = [ "wine" "winetricks" ];
  
  aurPackages = [
    "steam"
    "lutris"
    "heroic-games-launcher-bin"
  ];
  
  autoUpdate = false;
};
```

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

## Requirements

- NixOS or Nix package manager
- Home Manager
- Podman or Docker (distrobox requirement)
- distrobox (automatically installed by the module)

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

## Troubleshooting

### Unsupported distro error

If you see an error like:
```
error: Container 'mycontainer' has unsupported distro 'unknown'. Supported distros: arch, ubuntu, debian, fedora, centos, opensuse, alpine
```

This means you specified an unsupported distro. Use one of the supported distros:

```nix
programs.distrobox.containers.mycontainer = {
  distro = "ubuntu";  # Must be one of the supported distros
  image = "myimage:latest";
  packages = [ ... ];
};
```

### Container creation fails

Ensure you have Podman or Docker installed and running:

```bash
# For Podman
systemctl --user start podman.socket

# Check status
podman ps
```

### Package installation fails

Check the package manager logs:

```bash
distrobox enter arch
journalctl -xe
```

### AUR installation fails

Make sure `base-devel` and `git` are installed (required for building AUR packages):

```nix
programs.distrobox.containers.arch = {
  distro = "arch";
  image = "archlinux:latest";
  packages = [ "base-devel" "git" ];  # Required for AUR
  aurPackages = [ "paru-bin" ];
};
```

### Permission issues

Some operations require sudo inside the container. The module automatically uses `sudo` for package installation.

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

### Code Formatting

Format all code using treefmt:

```bash
treefmt
```

Or format Nix files only:

```bash
nixpkgs-fmt .
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

When contributing:
1. Use the development shell (`nix-shell`)
2. Format your code with `treefmt` before committing
3. Test your changes with actual distrobox containers

## License

MIT

## Related Projects

- [distrobox](https://github.com/89luca89/distrobox) - The underlying container tool
- [home-manager](https://github.com/nix-community/home-manager) - Declarative dotfile management
- [nixpkgs](https://github.com/NixOS/nixpkgs) - The Nix package collection
