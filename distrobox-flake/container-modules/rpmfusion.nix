{ lib, ... }:

with lib;

{
  options.rpmfusion = {
    free = mkOption {
      type = types.bool;
      default = false;
      description = "Enable RPM Fusion Free repository (Fedora only).";
    };
    nonfree = mkOption {
      type = types.bool;
      default = false;
      description = "Enable RPM Fusion Nonfree repository (Fedora only).";
    };
  };
}
