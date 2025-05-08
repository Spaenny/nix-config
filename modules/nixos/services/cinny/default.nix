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

    package = mkOption {
      description = "The package of Cinny to use.";
      type = types.package;
      default = pkgs.cinny-unwrapped;
    };

    port = mkOption {
      description = "The port to serve Cinny on.";
      type = types.nullOr types.int;
      default = 8686;
    };

  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      cfg.port
    ];

    services.caddy = {
      enable = true;
      virtualHosts.":${builtins.toString cfg.port}" = {
        extraConfig = ''
          root * ${cfg.package}
          file_server

          @index {
            not path /index.html
            not path /public/*
            not path /assets/*

            not path /config.json

            not path /manifest.json
            not path /sw.js

            not path /pdf.worker.min.js
            not path /olm.wasm

            path /*
          }

          rewrite /*/olm.wasm /olm.wasm
          rewrite @index /index.html
        '';
      };
    };
  };
}
