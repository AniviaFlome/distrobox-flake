{ config, lib, ... }:

let
  cfg = config.programs.distrobox-flake;
  distroboxCfg = config.programs.distrobox;

  containersFile = "${config.xdg.configHome}/distrobox/containers.ini";
  distroboxBin = "${distroboxCfg.package}/bin/distrobox-assemble";
in
{
  options.programs.distrobox-flake.assemble = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run distrobox assemble create via a systemd timer.";
    };
    timerInterval = lib.mkOption {
      type = lib.types.str;
      default = "1h";
      description = "How often the systemd timer re-runs distrobox assemble (OnUnitActiveSec).";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.assemble.enable && distroboxCfg.package != null) {
    systemd.user.services.distrobox-flake-assemble = {
      Unit.Description = "Run distrobox assemble to create/update declared containers";
      Service = {
        Type = "oneshot";
        ExecStart = "${distroboxBin} create --file ${containersFile}";
        Environment = "PATH=/run/current-system/sw/bin:${distroboxCfg.package}/bin";
      };
    };

    systemd.user.timers.distrobox-flake-assemble = {
      Unit.Description = "Periodically run distrobox assemble";
      Timer = {
        OnBootSec = "2min";
        OnUnitActiveSec = cfg.assemble.timerInterval;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
