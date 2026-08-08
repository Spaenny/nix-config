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
  cfg = config.${namespace}.services.forgejo;
  codebergThemes = pkgs.${namespace}.codeberg-themes;
in
{
  options.${namespace}.services.forgejo = {
    enable = mkEnableOption "Forgejo";
    nginx = {
      enable = mkEnabledOption "Enable nginx for this service.";
    };

    package = mkOption {
      description = "The package of Forgejo to use.";
      type = types.package;
      default = pkgs.forgejo;
    };

    port = mkOption {
      description = "The port to serve Forgejo on.";
      type = types.port;
      default = 3001;
    };

    domain = mkOption {
      description = "The domain to serve Forgejo on.";
      type = types.str;
      default = "git.stahl.sh";
    };

    ssh_domain = mkOption {
      description = "The domain to serve Forgejo on.";
      type = types.str;
      default = "stahl.sh";
    };

    user = mkOption {
      description = "The user to run Forgejo as.";
      type = types.str;
      default = "forgejo";
    };

  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
      80
      443
    ];

    systemd.services.codeberg-themes = {
      description = "Codeberg Themes Setup";
      wantedBy = [ "forgejo.service" ];
      before = [ "forgejo.service" ];
      path = [ pkgs.coreutils ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "setup-codeberg-themes" ''
          set -euo pipefail

          install -d -o ${cfg.user} -g ${cfg.user} \
            /var/lib/forgejo/custom/public/assets/css \
            /var/lib/forgejo/custom/public/assets/img

          cp -r ${codebergThemes}/var/lib/forgejo/custom/public/assets/css/* \
            /var/lib/forgejo/custom/public/assets/css/
          cp ${codebergThemes}/var/lib/forgejo/custom/public/assets/img/*logo.svg \
            /var/lib/forgejo/custom/public/assets/img/logo.svg

          chown -R ${cfg.user}:${cfg.user} /var/lib/forgejo/custom
        '';
      };
    };

    services.forgejo = {
      enable = true;
      inherit (cfg)
        package
        user
        ;

      database = {
        inherit (cfg) user;
        type = "postgres";
      };

      settings = {
        server = {
          DOMAIN = cfg.domain;
          HTTP_PORT = cfg.port;
          ROOT_URL = "https://" + cfg.domain;
          SSH_DOMAIN = cfg.ssh_domain;
        };
        ui = {
          DEFAULT_THEME = "codeberg-dark";
          THEMES = "codeberg-dark";
        };
      };
    };

    virtualisation.docker.enable = true;

    ${namespace}.services.acme.enable = mkIf cfg.nginx.enable true;

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;

      virtualHosts."${cfg.domain}" = mkNginxProxyHost {
        proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}";
      };
    };
  };
}
