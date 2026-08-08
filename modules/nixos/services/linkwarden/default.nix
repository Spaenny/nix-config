{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.linkwarden;
  sopsCfg = config.${namespace}.system.sops;

  inherit (lib)
    types
    mkIf
    mkOption
    mkEnableOption
    ;
  inherit (lib.${namespace})
    enabled
    mkEnabledOption
    mkNginxProxyHost
    mkSopsDotenvSecret
    ;
in
{
  options.${namespace}.services.linkwarden = {
    enable = mkEnableOption "Linkwarden";
    package = lib.mkPackageOption pkgs "linkwarden" { };
    nginx = {
      enable = mkEnabledOption "Enable nginx for this service.";
    };

    domain = mkOption {
      description = "The domain to serve linkwarden on.";
      type = types.str;
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
    ${namespace}.system.sops = enabled;

    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
      80
      443
    ];

    services.linkwarden = {
      enable = true;
      inherit (cfg)
        host
        port
        ;
      environmentFile = config.sops.secrets.linkwarden.path;
    };

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;

      virtualHosts."${cfg.domain}" = mkNginxProxyHost {
        proxyPass = "http://${cfg.host}:${builtins.toString cfg.port}";
      };
    };

    sops.secrets.linkwarden = mkSopsDotenvSecret sopsCfg.secretsDir "blarm-linkwarden.env";

    meta.maintainers = with lib.maintainers; [ jvanbruegge ];
  };
}
