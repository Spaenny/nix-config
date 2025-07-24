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
  cfg = config.${namespace}.services.syncthing;
in
{
  options.${namespace}.services.syncthing = {
    enable = mkEnableOption "Syncthing";

    port = mkOption {
      description = "The port to serve Syncthing on.";
      type = types.nullOr types.int;
      default = 8384;
    };

    ip = mkOption {
      description = "The ip to serve Syncthing on.";
      type = types.nullOr types.str;
      default = "192.168.10.3";
    };

    openDefaultPorts = mkEnableOption "Whether to open the default ports in the firewall.";

  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      cfg.port
    ];

    services.syncthing = {
      enable = true;
      guiAddress = "${cfg.ip}:${toString cfg.port}";
      openDefaultPorts = mkIf cfg.openDefaultPorts true;
      dataDir = "/data/syncthing";
    };
  };
}
