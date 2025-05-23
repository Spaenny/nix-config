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
    redlib = mkBoolOpt true "Whether or not to enable redlib.";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 1340 ];

    services.searx = {
      enable = true;
      environmentFile = "/run/secrets/searxng";
      settings.server = {
        port = "1340";
        bind_address = "0.0.0.0";
        use_default_settings = true;
        secret_key = "@secret_key@";
      };
    };

    services.redlib = mkIf cfg.redlib {
      enable = true;
      address = "0.0.0.0";
      port = 1341;
      openFirewall = true;
    };

    services.searx.settings.searx = mkIf cfg.redlib {
      plugins.hostnames.SXNGPlugin.active = true;
    };

    services.searx.settings.hostnames.replace = mkIf cfg.redlib {
      "(.*\.)?reddit\.com$" = "reddit.monapona.dev";
      "(.*\.)?redd\.it$" = "reddit.monapona.dev";
    };

    sops.secrets.searxng = {
      format = "dotenv";
      sopsFile = ../../../../secrets/blarm-searxng.env;
    };

  };

}
