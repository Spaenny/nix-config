{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.caddy;
in
{
  options.${namespace}.services.caddy = {
    enable = mkEnableOption "Caddy";
  };

  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;
      virtualHosts = {
        ":1338" = {
          extraConfig = ''
            root * /var/lib/caddy/ente
            file_server
          '';
        };
        ":1339" = {
          extraConfig = ''
            reverse_proxy 192.168.1.241:3080
          '';
        };
        ":8686" = {
          extraConfig = ''
            root * /var/lib/caddy/cinny
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
  };
}
