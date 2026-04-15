{ lib }:

let
  exportAppHooks = apps: map (app: "distrobox-export --app ${lib.escapeShellArg app}") apps;

  exportBinaryHooks =
    binaries:
    lib.mapAttrsToList (
      bin: exportPath:
      "distrobox-export --bin ${lib.escapeShellArg bin} --export-path ${lib.escapeShellArg exportPath}"
    ) binaries;
in
{
  options.export = {
    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Application names to export to the host application menu via distrobox-export --app.";
      example = [
        "firefox"
        "org.gnome.Calculator"
      ];
    };

    binaries = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Binaries to export to the host. Maps the absolute path of the binary inside the container to the export directory on the host.";
      example = {
        "/usr/bin/htop" = "~/.local/bin";
        "/usr/bin/nvim" = "~/.local/bin";
      };
    };
  };

  mkContainerConfig = containerCfg: {
    init_hooks =
      exportAppHooks containerCfg.export.apps ++ exportBinaryHooks containerCfg.export.binaries;
  };

  hasFeature = containerCfg: containerCfg.export.apps != [ ] || containerCfg.export.binaries != { };
}
