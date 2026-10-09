{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.lact;
in
{
  options.${namespace}.services.lact = with types; {
    enable = mkEnableOption "Control fan curves via the lact tool.";
    fanCurve = mkOption {
      type = str;
      default = "1000:70,2000:85,3000:100";
      description = "Comma‑separated list of <speed>:<temperature> pairs. 0‑1000 are fan speed percentages; temperatures in Celsius. The lact binary will be invoked with these values to set the fan curve."
    };
  };

  config = mkIf cfg.enable {
    systemd.services.lact = {
      description = "lact fan‑curve controller";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.lact}/bin/lact --curve ${cfg.fanCurve}";
        Restart = "on-failure";
        RestartSec = 30;
      };
    };
  };
}
