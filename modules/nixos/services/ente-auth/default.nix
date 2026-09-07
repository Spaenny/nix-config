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

  enteApp = cfg.package.override {
    extraBuildEnv = {
      NEXT_PUBLIC_ENTE_ENDPOINT = cfg.apiEndpoint;
      NEXT_TELEMETRY_DISABLED = "1";
    };
  };
in
{
  options.${namespace}.services.ente-auth = {
    enable = mkEnableOption "Ente-Auth";

    package = mkOption {
      description = "The package of Ente-Auth to use.";
      type = types.package;
      default = pkgs.${namespace}.ente-web-auth;
    };

    domain = mkOption {
      description = "The domain to serve ente-auth on.";
      type = types.str;
      default = "ente.stahl.sh";
    };

    apiEndpoint = mkOption {
      description = "The public Ente API endpoint used by the Auth frontend.";
      type = types.str;
      default = "https://ente.stahl.sh/api";
    };

    nginx = {
      enable = mkEnabledOption "Enable nginx for this service.";
    };

  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
      80
      443
    ];

    ${namespace}.services.acme.enable = mkIf cfg.nginx.enable true;

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;

      virtualHosts."${cfg.domain}" = mkNginxStaticHost {
        root = enteApp;
        location = {
          extraConfig = ''
            try_files $uri $uri/ /index.html;
          '';
        };
      };
    };
  };

}
