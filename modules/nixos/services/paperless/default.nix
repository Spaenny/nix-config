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
  cfg = config.${namespace}.services.paperless;
in
{
  options.${namespace}.services.paperless = {
    enable = mkEnableOption "Paperless";
    nginx = {
      enable = mkEnabledOption "Enable nginx for this service.";
    };

    package = mkOption {
      description = "The package of Paperless to use.";
      type = types.package;
      default = pkgs.paperless-ngx;
    };

    port = mkOption {
      description = "The port to serve Paperless on.";
      type = types.port;
      default = 28981;
    };

    domain = mkOption {
      description = "The domain to serve Paperless on.";
      type = types.str;
      default = "paperless.stahl.sh";
    };

  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
      80
      443
    ];

    services = {
      paperless = {
        enable = true;
        inherit (cfg)
          package
          port
          ;
        dataDir = "/data/paperless";
        consumptionDirIsPublic = true;
        settings = {
          PAPERLESS_OCR_LANGUAGE = "deu+eng";
          PAPERLESS_OCR_USER_ARGS = {
            optimize = 1;
            pdfa_image_compression = "lossless";
          };
          PAPERLESS_DBHOST = ""; # Ensure sqlite database
          PAPERLESS_URL = "https://${cfg.domain}";
        };
      };

      nginx = mkIf cfg.nginx.enable {
        enable = true;

        virtualHosts."${cfg.domain}" = mkNginxProxyHost {
          proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}";
          location = {
            recommendedProxySettings = true;
          };
        };
      };
    };

    ${namespace}.services.acme.enable = mkIf cfg.nginx.enable true;
  };
}
