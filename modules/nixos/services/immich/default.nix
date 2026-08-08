{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.immich;
  sopsCfg = config.${namespace}.system.sops;
in
{
  options.${namespace}.services.immich = {
    enable = mkBoolOpt false "Immich";

    nginx = {
      enable = mkEnabledOption "Enable nginx for this service.";
    };

    domain = mkOption {
      description = "The domain to serve Immich on.";
      type = types.str;
      default = "immich.stahl.sh";
    };

    port = mkOption {
      description = "The port that Immich will listen on.";
      type = types.port;
      default = 2283;
    };
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      system.sops = enabled;
      services.acme.enable = mkIf cfg.nginx.enable true;
    };

    services = {
      immich = {
        enable = true;
        mediaLocation = "/data/immich";
        host = "0.0.0.0";
        inherit (cfg) port;
        secretsFile = config.sops.secrets.immich.path;
        redis.enable = true;
        machine-learning.enable = true;
        database = {
          enable = true;
          createDB = false;
        };
      };

      postgresql.extensions = ps: with ps; [ pgvector ];

      nginx = mkIf cfg.nginx.enable {
        enable = true;

        virtualHosts."${cfg.domain}" = mkNginxProxyHost {
          proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}";
          location = {
            proxyWebsockets = true;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
      cfg.port
      80
      443
    ];

    sops.secrets.immich = mkSopsDotenvSecret sopsCfg.secretsDir "blarm-immich.env";
  };

}
