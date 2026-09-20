{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.nginx;
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) enabled;
in
{
  options.${namespace}.services.nginx.enable = mkEnableOption "Nginx with a TLS fallback virtual host";

  config = mkIf cfg.enable {
    ${namespace}.services.acme = enabled;

    services.nginx = {
      enable = true;
      # Unknown hostnames must not fall through to the first application vhost.
      virtualHosts."_" = {
        default = true;
        addSSL = true;
        useACMEHost = "stahl.sh";
        locations."/".return = "404";
      };
    };
  };
}
