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
  cfg = config.${namespace}.services.cinny;
in
{
  options.${namespace}.services.cinny = {
    enable = mkEnableOption "Cinny";
    nginx = {
      enable = mkEnabledOption "Enable nginx for this service.";
    };

    package = mkOption {
      description = "The package of Cinny to use.";
      type = types.package;
      default = pkgs.cinny-unwrapped;
    };

    domain = mkOption {
      description = "The domain to serve Cinny on.";
      type = types.str;
      default = "cinny.stahl.sh";
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
        root = "${cfg.package}";
        location = {
          extraConfig = ''
            rewrite ^/config.json$ /config.json break;
            rewrite ^/manifest.json$ /manifest.json break;

            rewrite ^/sw.js$ /sw.js break;
            rewrite ^/pdf.worker.min.js$ /pdf.worker.min.js break;

            rewrite ^/public/(.*)$ /public/$1 break;
            rewrite ^/assets/(.*)$ /assets/$1 break;

            rewrite ^/element-call/dist/(.*)$ /element-call/dist/$1 break;

            rewrite ^(.+)$ /index.html break;
          '';
        };
      };
    };
  };

}
