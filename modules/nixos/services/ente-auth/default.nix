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

    port = mkOption {
      description = "The port to serve Ente-Auth on.";
      type = types.nullOr types.int;
      default = 1338;
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      cfg.port
    ];

    services.caddy = {
      enable = true;
      virtualHosts = {
        ":${builtins.toString cfg.port}" = {
          extraConfig = ''
            root * ${cfg.package}
            file_server
          '';
        };
      };
    };
  };
}
