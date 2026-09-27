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

    services.nginx.virtualHosts."${cfg.statsDomain}" = mkNginxProxyHost {
      proxyPass = "http://127.0.0.1:3002";
      location = {
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };
  };
}
