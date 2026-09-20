{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.opencloud;
  cloudUrl = "https://${cfg.domain}";
  collaboraUrl = "https://${cfg.collaboraDomain}";
  wopiUrl = "https://${cfg.wopiDomain}";
  stateDir = "${cfg.dataDir}/data";
  configDir = "${cfg.dataDir}/config";
in
{
  options.${namespace}.services.opencloud = {
    enable = mkEnableOption "native OpenCloud server";

    domain = mkOption {
      description = "Public OpenCloud domain.";
      type = types.str;
      default = "cloud.stahl.sh";
    };

    collaboraDomain = mkOption {
      description = "Public Collabora Online domain.";
      type = types.str;
      default = "collabora.stahl.sh";
    };

    wopiDomain = mkOption {
      description = "Public OpenCloud WOPI domain.";
      type = types.str;
      default = "wopiserver.stahl.sh";
    };

    dataDir = mkOption {
      description = "Root directory for persistent OpenCloud data and configuration.";
      type = types.path;
      default = "/data/opencloud";
    };
  };

  config = mkIf cfg.enable {
    ${namespace}.services.acme.enable = true;

    services.opencloud = {
      enable = true;
      inherit stateDir;
      url = cloudUrl;
      address = "127.0.0.1";
      port = 9200;
      environment = {
        OC_CONFIG_DIR = configDir;
        OC_INSECURE = "false";
        OC_LOG_LEVEL = "info";
        OC_LOG_COLOR = "false";
        OC_LOG_PRETTY = "false";
        OC_ADD_RUN_SERVICES = "collaboration";
        COLLABORA_DOMAIN = cfg.collaboraDomain;
        FRONTEND_APP_HANDLER_SECURE_VIEW_APP_ADDR = "eu.opencloud.api.collaboration";
        COLLABORATION_APP_ADDR = collaboraUrl;
        COLLABORATION_APP_ICON = "${collaboraUrl}/favicon.ico";
        COLLABORATION_APP_INSECURE = "false";
        COLLABORATION_CS3API_DATAGATEWAY_INSECURE = "false";
        COLLABORATION_HTTP_ADDR = "127.0.0.1:9300";
        COLLABORATION_WOPI_SRC = wopiUrl;
        MICRO_REGISTRY = "nats-js-kv";
        MICRO_REGISTRY_ADDRESS = "127.0.0.1:9233";
        NATS_NATS_HOST = "127.0.0.1";
        PROXY_ENABLE_BASIC_AUTH = "false";
        PROXY_TLS = "false";
        # Keep 9100 free for the Prometheus node exporter.
        WEB_HTTP_ADDR = "127.0.0.1:9101";
      };
    };

    systemd.services.opencloud = {
      after = [ "data.mount" ];
      requires = [ "data.mount" ];
      serviceConfig = {
        ReadWritePaths = mkForce [ cfg.dataDir ];
        ReadOnlyPaths = [ configDir ];
      };
    };

    systemd.services.opencloud-init-config.serviceConfig.ReadWritePaths = mkForce [ configDir ];

    services.collabora-online = {
      enable = true;
      port = 9980;
      aliasGroups = [
        {
          host = wopiUrl;
          aliases = [ cloudUrl ];
        }
      ];
      settings = {
        ssl = {
          enable = false;
          termination = true;
        };
        welcome.enable = false;
        home_mode.enable = true;
        net.frame_ancestors = cfg.domain;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "${cfg.domain}" = mkNginxProxyHost {
          proxyPass = "http://127.0.0.1:9200";
          location = {
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
        "${cfg.collaboraDomain}" = mkNginxProxyHost {
          proxyPass = "http://127.0.0.1:9980";
          location = {
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
        "${cfg.wopiDomain}" = mkNginxProxyHost {
          proxyPass = "http://127.0.0.1:9300";
          location = {
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 opencloud opencloud -"
      "d ${stateDir} 0750 opencloud opencloud -"
      "d ${configDir} 0750 opencloud opencloud -"
      "d ${cfg.dataDir}/apps 0750 opencloud opencloud -"
    ];
  };
}
