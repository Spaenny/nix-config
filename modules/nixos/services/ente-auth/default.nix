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
  cfg = config.${namespace}.services.ente-auth;
in
{
  options.${namespace}.services.ente-auth = {
    enable = mkEnableOption "Ente-Auth";

    package = mkOption {
      description = "The package of Ente-Auth to use.";
      type = types.package;
      default = pkgs.awesome-flake.ente-web-auth;
    };

    domain = mkOption {
      description = "The domain to serve ente-auth on.";
      type = types.nullOr types.str;
      default = "ente.stahl.sh";
    };

    nginx = {
      enable = mkEnableOption "Enable nginx for this service."
      // {
          default = true;
      };
    };

  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
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
          root = "${cfg.package}";
        };
      };
    };
  };

}
