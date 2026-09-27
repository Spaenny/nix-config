{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.monitoring;
  sopsCfg = config.${namespace}.system.sops;
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkNginxProxyHost mkSopsSecret;
in
{
  config = mkIf cfg.enable {
    sops.secrets."monitoring/prometheus-htpasswd" = mkSopsSecret sopsCfg.secretsDir "blarm-monitoring.yaml" {
      key = "prometheus_htpasswd";
      owner = "nginx";
      group = "nginx";
      mode = "0400";
      restartUnits = [ "nginx.service" ];
    };

    services.prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9090;
      retentionTime = "15d";

      exporters.node = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9100;
        openFirewall = false;
        enabledCollectors = [ "systemd" ];
      };

      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [ { targets = [ "127.0.0.1:9090" ]; } ];
        }
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
              labels.instance = cfg.instance;
            }
          ];
        }

        # VyOS router exporters
        {
          job_name = "vyos-node";
          static_configs = [
            {
              targets = [ "192.168.10.1:9100" ];
              labels.instance = "vyos";
            }
          ];
        }
      ];
    };

    services.nginx.virtualHosts."collector.stahl.sh" = mkNginxProxyHost {
      proxyPass = "http://127.0.0.1:9090";
      basicAuthFile = config.sops.secrets."monitoring/prometheus-htpasswd".path;
      location.recommendedProxySettings = true;
    };
  };
}
