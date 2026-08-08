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
  cfg = config.${namespace}.services.searxng;
  sopsCfg = config.${namespace}.system.sops;
in
{
  options.${namespace}.services.searxng = with types; {
    enable = mkBoolOpt false "SearXNG";

    domain = mkOption {
      description = "The domain to serve searxng on.";
      type = types.str;
      default = "search.stahl.sh";
    };

    nginx = {
      enable = mkEnabledOption "Enable nginx for this service.";
    };

    redlib = {
      enable = mkEnabledOption "Whether or not to enable redlib.";

      domain = mkOption {
        description = "The domain to serve reddit on.";
        type = types.str;
        default = "reddit.stahl.sh";
      };
    };
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      system.sops = enabled;
      services.acme.enable = mkIf cfg.nginx.enable true;
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
      80
      443
    ];

    services = {
      searx = {
        enable = true;
        environmentFile = config.sops.secrets.searxng.path;
        settings = {
          server = {
            port = "1340";
            bind_address = "127.0.0.1";
            use_default_settings = true;
            secret_key = "@secret_key@";
          };
          search = {
            safe_search = 0;
            autocomplete = "google";
          };
          searx = mkIf cfg.redlib.enable {
            plugins.hostnames.SXNGPlugin.active = true;
          };
          hostnames.replace = mkIf cfg.redlib.enable {
            "(.*\.)?reddit\.com$" = cfg.redlib.domain;
            "(.*\.)?redd\.it$" = cfg.redlib.domain;
          };
        };
      };

      redlib = mkIf cfg.redlib.enable {
        package = pkgs.redlib;
        enable = true;
        address = "127.0.0.1";
        port = 1341;
      };

      nginx = mkIf cfg.nginx.enable {
        enable = true;

        virtualHosts = {
          "${cfg.domain}" = mkNginxProxyHost {
            proxyPass = "http://127.0.0.1:1340";
          };
          "${cfg.redlib.domain}" = mkIf cfg.redlib.enable (mkNginxProxyHost {
            proxyPass = "http://127.0.0.1:1341";
          });
        };
      };
    };

    sops.secrets.searxng = mkSopsDotenvSecret sopsCfg.secretsDir "blarm-searxng.env";

  };

}
