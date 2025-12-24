{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.linkwarden;
  isPostgresUnixSocket = lib.hasPrefix "/" cfg.database.host;

  inherit (lib)
    types
    mkIf
    mkOption
    mkEnableOption
    ;
in
{
  options.${namespace}.services.linkwarden = {
    enable = mkEnableOption "Linkwarden";
    package = lib.mkPackageOption pkgs "linkwarden" { };
    nginx = {
      enable = mkEnableOption "Enable nginx for this service." // {
        default = true;
      };
    };

    domain = mkOption {
      description = "The domain to serve linkwarden on.";
      type = types.nullOr types.str;
      default = "link.stahl.sh";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "The host that Linkwarden will listen on.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "The port that Linkwarden will listen on.";
    };

  };

  config = mkIf cfg.enable {
    services.linkwarden = {
      enable = true;
      host = cfg.host;
      port = cfg.port;
      environmentFile = "/run/secrets/linkwarden";
    };

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;

      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        useACMEHost = "stahl.sh";
        locations."/".proxyPass = "http://${cfg.host}:${builtins.toString cfg.port}";
      };
    };

    sops.secrets.linkwarden = {
      format = "dotenv";
      sopsFile = ../../../../secrets/blarm-linkwarden.env;
    };

    meta.maintainers = with lib.maintainers; [ jvanbruegge ];
  };
}
