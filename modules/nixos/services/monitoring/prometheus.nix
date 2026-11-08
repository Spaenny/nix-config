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

    # Whole pve.yml (PVE API token) for the Proxmox exporter: the file holds a
    # credential, so it must not live in the store. Root-readable is enough —
    # systemd hands it to the service through LoadCredential.
    sops.secrets."monitoring/pve-exporter-config" =
      mkSopsSecret sopsCfg.secretsDir "blarm-pve-exporter.yaml"
        {
          key = ""; # whole file: it is a complete pve.yml
          mode = "0400";
          restartUnits = [ "prometheus-pve-exporter.service" ];
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

      # Proxmox VE exporter: prometheus asks it for /pve?target=pve.monapona.de:443.
      exporters.pve = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9221;
        openFirewall = false;
        configFile = config.sops.secrets."monitoring/pve-exporter-config".path;
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

        # cAdvisor on the cancer host (Docker container metrics)
        {
          job_name = "cancer-container";
          metrics_path = "/metrics";
          label_value_length_limit = 512;
          label_limit = 64;
          sample_limit = 10000;
          static_configs = [
            {
              targets = [ "192.168.100.3:9180" ];
              labels.instance = "cancer.boehm.sh";
            }
          ];
          metric_relabel_configs = [
            {
              source_labels = [ "instance" ];
              target_label = "node";
            }
            {
              source_labels = [ "name" ];
              target_label = "container";
            }
            # Container name is the fallback for the service label …
            {
              source_labels = [ "name" ];
              target_label = "service";
            }
            # … overridden by the compose service name where it exists.
            {
              source_labels = [ "container_label_com_docker_compose_service" ];
              regex = "(.+)";
              target_label = "service";
              replacement = "$1";
            }
          ];
        }

        # Proxmox VE exporter (prometheus-pve-exporter, /pve endpoint)
        {
          job_name = "proxmox";
          metrics_path = "/pve";
          params = {
            module = [ "default" ];
            target = [ "pve.monapona.de:443" ];
          };
          static_configs = [ { targets = [ "127.0.0.1:9221" ]; } ];
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
