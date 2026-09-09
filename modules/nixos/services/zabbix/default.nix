{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.zabbix;
in
{
  options.${namespace}.services.zabbix = {
    enable = mkEnableOption "Zabbix monitoring server and agent";

    domain = mkOption {
      description = "Public Zabbix web interface domain.";
      type = types.str;
      default = "zabbix.stahl.sh";
    };

    hostname = mkOption {
      description = "Zabbix host name used by the local agent.";
      type = types.str;
      default = "blarm";
    };
  };

  config = mkIf cfg.enable {
    ${namespace}.services.acme.enable = true;

    services.zabbixServer = {
      enable = true;
      openFirewall = true;
      database = {
        type = "pgsql";
        createLocally = true;
      };
    };

    services.zabbixWeb = {
      enable = true;
      frontend = "nginx";
      hostname = cfg.domain;
      database.type = "pgsql";
      nginx.virtualHost = {
        forceSSL = true;
        useACMEHost = "stahl.sh";
      };
    };

    services.phpfpm.pools.zabbix.phpPackage = pkgs.php83;

    services.zabbixAgent = {
      enable = true;
      server = "127.0.0.1";
      settings = {
        Hostname = cfg.hostname;
        ServerActive = "127.0.0.1";
      };
    };
  };
}
