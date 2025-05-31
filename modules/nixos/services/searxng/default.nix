{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.searxng;
in
{
  options.${namespace}.services.searxng = with types; {
    enable = mkBoolOpt false "SearXNG";

    domain = mkOption {
      description = "The domain to serve searxng on.";
      type = types.nullOr types.str;
      default = "search.stahl.sh";
    };

    nginx = {
      enable = mkEnableOption "Enable nginx for this service." // {
        default = true;
      };
    };

    redlib = {
      enable = mkEnableOption "Whether or not to enable redlib." // {
        default = true;
      };

      domain = mkOption {
        description = "The domain to serve reddit on.";
        type = types.nullOr types.str;
        default = "reddit.stahl.sh";
      };
    };

  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
      80
      443
    ];

    services.searx = {
      enable = true;
      environmentFile = "/run/secrets/searxng";
      settings.server = {
        port = "1340";
        bind_address = "127.0.0.1";
        use_default_settings = true;
        secret_key = "@secret_key@";
      };
    };

    services.redlib = mkIf cfg.redlib.enable {
      enable = true;
      address = "127.0.0.1";
      port = 1341;
    };

    services.searx.settings.searx = mkIf cfg.redlib.enable {
      plugins.hostnames.SXNGPlugin.active = true;
    };

    services.searx.settings.hostnames.replace = mkIf cfg.redlib.enable {
      "(.*\.)?reddit\.com$" = cfg.redlib.domain;
      "(.*\.)?redd\.it$" = cfg.redlib.domain;
    };

    awesome-flake.services.acme.enable = mkIf cfg.nginx.enable true;

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;

      virtualHosts = {
        "${cfg.domain}" = {
          forceSSL = true;
          useACMEHost = "stahl.sh";
          locations."/".proxyPass = "http://127.0.01:1340";
        };
        "${cfg.redlib.domain}" = mkIf cfg.redlib.enable {
          forceSSL = true;
          useACMEHost = "stahl.sh";
          locations."/".proxyPass = "http://127.0.01:1341";
        };
      };
    };

    sops.secrets.searxng = {
      format = "dotenv";
      sopsFile = ../../../../secrets/blarm-searxng.env;
    };

  };

}
