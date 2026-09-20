{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.monitoring;
  sopsCfg = config.${namespace}.system.sops;
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) enabled mkNginxProxyHost mkOpt mkSopsSecret;

  # Blackbox exporter running locally on this host.
  # Ports 9100/9115 are already taken by node exporter / OpenCloud notifications.
  blackboxExporter = "127.0.0.1:9116";

  blackboxConfig = pkgs.writeText "blackbox-exporter.yaml" ''
    modules:
      icmp4:
        prober: icmp
        timeout: 5s
        icmp:
          preferred_ip_protocol: ip4
      icmp6:
        prober: icmp
        timeout: 5s
        icmp:
          preferred_ip_protocol: ip6
      https_2xx:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          ip_protocol_fallback: true
          follow_redirects: true
  '';

  ## Blackbox probe job: rewrites each target into the exporter's /probe endpoint.
  mkProbeJob =
    job_name: module: targets:
    {
      inherit job_name;
      metrics_path = "/probe";
      params.module = [ module ];
      static_configs = [ { inherit targets; } ];
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = blackboxExporter;
        }
      ];
    };
in
{
  imports = [ ./kanidm.nix ];

  options.${namespace}.services.monitoring = {
    enable = mkEnableOption "Grafana and Prometheus monitoring";

    instance = mkOpt lib.types.str config.networking.hostName "Instance label for scraped node metrics.";

    statsDomain = mkOpt lib.types.str "stats.stahl.sh" "Public domain of the Grafana instance.";
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      system.sops = enabled;
      services.acme = enabled;
    };

    sops.secrets = {
      "monitoring/grafana-admin-password" = mkSopsSecret sopsCfg.secretsDir "blarm-monitoring.yaml" {
        key = "grafana_admin_password";
        owner = "grafana";
        group = "grafana";
        mode = "0400";
        restartUnits = [ "grafana.service" ];
      };
      "monitoring/grafana-secret-key" = mkSopsSecret sopsCfg.secretsDir "blarm-monitoring.yaml" {
        key = "grafana_secret_key";
        owner = "grafana";
        group = "grafana";
        mode = "0400";
        restartUnits = [ "grafana.service" ];
      };
      "monitoring/prometheus-htpasswd" = mkSopsSecret sopsCfg.secretsDir "blarm-monitoring.yaml" {
        key = "prometheus_htpasswd";
        owner = "nginx";
        group = "nginx";
        mode = "0400";
        restartUnits = [ "nginx.service" ];
      };
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3002;
          domain = cfg.statsDomain;
          root_url = "https://${cfg.statsDomain}/";
        };
        security = {
          admin_user = "admin";
          admin_password = "$__file{${config.sops.secrets."monitoring/grafana-admin-password".path}}";
          secret_key = "$__file{${config.sops.secrets."monitoring/grafana-secret-key".path}}";
          cookie_secure = true;
        };
        "auth.anonymous".enabled = false;
        users.allow_sign_up = false;
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            uid = "prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            isDefault = true;
            editable = false;
          }
        ];
      };
    };

    services.prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9090;
      retentionTime = "15d";
      exporters = {
        node = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = 9100;
          openFirewall = false;
        };
        blackbox = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = 9116;
          configFile = blackboxConfig;
        };
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
          static_configs = [ { targets = [ "192.168.10.1:9100" ]; } ];
        }
        # Blackbox exporter (local)
        {
          job_name = "blackbox-exporter";
          static_configs = [ { targets = [ blackboxExporter ]; } ];
        }

        # Blackbox probes
        (mkProbeJob "vyos-icmp4" "icmp4" [
          "192.168.5.100"
          "192.168.5.200"
        ])
        (mkProbeJob "vyos-icmp6" "icmp6" [
          "fdf3:567b:734c:5::100"
          "fdf3:567b:734c:5::200"
        ])
        (mkProbeJob "https_2xx" "https_2xx" [
          "https://auth.monapona.de"
          "https://jelly.monapona.de"
          "https://music.monapona.de"
          "https://im.monapona.de"
          "https://search.stahl.sh"
          "https://ente.stahl.sh"
          "https://boehm.sh"
          "https://matrix.boehm.sh"
          "https://serverlist.tf"
          "https://u0k.de"
          "https://git.stahl.sh"
          "https://git.snrd.eu"
        ])
      ];
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "${cfg.statsDomain}" = mkNginxProxyHost {
          proxyPass = "http://127.0.0.1:3002";
          location = {
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
        "collector.stahl.sh" = mkNginxProxyHost {
          proxyPass = "http://127.0.0.1:9090";
          basicAuthFile = config.sops.secrets."monitoring/prometheus-htpasswd".path;
          location.recommendedProxySettings = true;
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
