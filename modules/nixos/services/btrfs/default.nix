{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.btrfs;
in
{
  options.${namespace}.services.btrfs = {
    enable = mkBoolOpt false "BTRFS";
  };

  config = mkIf cfg.enable {
    services.btrfs.autoScrub.enable = true;
    services.fstrim.enable = true;

    environment.systemPackages = with pkgs; [ btrfs-progs ];
  };
}
