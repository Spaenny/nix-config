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

    ssh_user = mkOption {
      description = "The ssh user to use Forgejo as.";
      type = types.nullOr types.str;
      default = "forgejo";
    };

    domain = mkOption {
      description = "The domain to serve Forgejo on.";
      type = types.nullOr types.str;
      default = "git.monapona.dev";
    };

    ssh_domain = mkOption {
      description = "The domain to serve Forgejo on.";
      type = types.nullOr types.str;
      default = "monapona.dev";
    };

    user = mkOption {
      description = "The user to run Forgejo as.";
      type = types.nullOr types.str;
      default = "git";
    };

  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      cfg.port
    ];

    services.forgejo = {
      enable = true;
      package = cfg.package;
      database.type = "postgres";
      settings.server = {
        DOMAIN = cfg.domain;
        HTTP_PORT = cfg.port;
        ROOT_URL = "https://git.monapona.dev";
        SSH_DOMAIN = cfg.ssh_domain;
        BUILTIN_SSH_SERVER_USER = cfg.ssh_user;
      };
    };
  };
}
