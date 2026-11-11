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
  imports = [ ./kanidm.nix ];

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

    # Copy the themes in Forgejo's own preStart rather than a separate oneshot:
    # a finished oneshot is inactive, so switch-to-configuration never reran it
    # and theme updates never reached the disk. Here a new theme package
    # changes the Forgejo unit, which restarts it and copies the new files.
    systemd.services.forgejo.preStart = mkAfter ''
      assets=${config.services.forgejo.customDir}/public/assets
      install -d "$assets"
      # Earlier root copies left read-only directories from the Nix store.
      chmod -R u+w "$assets"
      cp -rT --no-preserve=mode,ownership --remove-destination \
        ${codebergThemes}/var/lib/forgejo/custom/public/assets "$assets"
    '';

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

    ${namespace}.services.acme.enable = mkIf cfg.nginx.enable true;

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;

      virtualHosts."${cfg.domain}" = mkNginxProxyHost {
        proxyPass = "http://127.0.0.1:${toString cfg.port}";
      };
    };
  };
}
