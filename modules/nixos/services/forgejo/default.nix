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
in
{
  options.${namespace}.services.forgejo = {
    enable = mkEnableOption "Forgejo";
    nginx = {
      enable = mkEnableOption {
        description = "Enable nginx for this service.";
        type = types.bool;
        default = true;
      };
    };

    package = mkOption {
      description = "The package of Forgejo to use.";
      type = types.package;
      default = pkgs.forgejo-lts;
    };

    port = mkOption {
      description = "The port to serve Forgejo on.";
      type = types.nullOr types.int;
      default = 3001;
    };

    domain = mkOption {
      description = "The domain to serve Forgejo on.";
      type = types.nullOr types.str;
      default = "git.stahl.sh";
    };

    ssh_domain = mkOption {
      description = "The domain to serve Forgejo on.";
      type = types.nullOr types.str;
      default = "stahl.sh";
    };

    user = mkOption {
      description = "The user to run Forgejo as.";
      type = types.nullOr types.str;
      default = "forgejo";
    };

  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    systemd.services.codeberg-themes = {
      description = "Codeberg Themes Setup";
      wantedBy = [ "multi-user.target" ];

      environment.PATH = lib.mkDefault "${pkgs.coreutils}/bin:${pkgs.bash}/bin";

      serviceConfig.ExecStart = ''
        ${pkgs.bash}/bin/bash -c "mkdir -p /var/lib/forgejo/custom/public/assets/css /var/lib/forgejo/custom/public/assets/img && \
          cp -r ${pkgs.awesome-flake.codeberg-themes}/var/lib/forgejo/custom/public/assets/css/* /var/lib/forgejo/custom/public/assets/css/ && \
          cp ${pkgs.awesome-flake.codeberg-themes}/var/lib/forgejo/custom/public/assets/img/*logo.svg /var/lib/forgejo/custom/public/assets/img/logo.svg && \
          chown -R ${cfg.user}:${cfg.user} /var/lib/forgejo/custom"
      '';
    };

    services.forgejo = {
      user = cfg.user;
      enable = true;
      package = cfg.package;

      database = {
        user = cfg.user;
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

    awesome-flake.services.acme.enable = mkIf cfg.nginx.enable true;

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;

      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        useACMEHost = "stahl.sh";
        locations."/".proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}";
      };
    };
  };
}
