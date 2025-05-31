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
in
{
  options.${namespace}.services.immich = {
    enable = mkBoolOpt false "Immich";

    nginx = {
      enable = mkEnableOption "Enable nginx for this service." // {
        default = true;
      };
    };

    domain = mkOption {
      description = "The domain to serve Immich on.";
      type = types.nullOr types.str;
      default = "immich.stahl.sh";
    };

    port = mkOption {
      type = types.port;
      default = 2283;
      description = "The port that Immich will listen on.";
    };
  };

  config = mkIf cfg.enable {

    services.immich = {
      enable = true;
      mediaLocation = "/data/immich";
      host = "0.0.0.0";
      port = cfg.port;
      secretsFile = "/run/secrets/immich";
      redis.enable = true;
      machine-learning.enable = true;
      database = {
        enable = true;
        createDB = false;
      };
    };

    services.postgresql.extensions = ps: with ps; [ pgvector ]; # Ensure pgvector is available

    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
      cfg.port
      80
      443
    ];

    awesome-flake.services.acme.enable = mkIf cfg.nginx.enable true;

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;

      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        useACMEHost = "stahl.sh";
        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}";
          proxyWebsockets = true;
        };
      };
    };

    sops.secrets.immich = {
      format = "dotenv";
      sopsFile = ../../../../secrets/blarm-immich.env;
    };
  };

}
