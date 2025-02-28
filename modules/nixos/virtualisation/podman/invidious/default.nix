{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.container.invidious;
in
{
  options.${namespace}.container.invidious = {
    enable = mkEnableOption "Invidious";
  };

  config = mkIf cfg.enable {
    sops.secrets.invidious-db = {
      format = "dotenv";
      sopsFile = ../../../../../secrets/invidious-db.env;
      key = "";
    };

    sops.secrets.invidious-config = {
      mode = "666";
      format = "yaml";
      sopsFile = ../../../../../secrets/invidious-config.yaml;
      key = "";
    };

    security.unprivilegedUsernsClone = true;

    virtualisation = {
      podman = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [ "--all" ];
        };
        defaultNetwork.settings = {
          dns_enabled = true;
        };
      };
    };

    virtualisation.oci-containers.containers = {
      invidious = {
        image = "quay.io/invidious/invidious:latest-arm64";
        hostname = "invidious";
        volumes = [ "/run/secrets/invidious-config:/invidious/config/config.yml" ];
        ports = [
          "192.168.1.202:3000:3000"
          "[fd00:192:168:1::202]:3000:3000"
        ];
        dependsOn = [ "invidious-db" ];
      };
      signature-helper = {
        image = "quay.io/invidious/inv-sig-helper:latest";
        hostname = "signature-helper";
        cmd = [
          "--tcp"
          "0.0.0.0:12999"
        ];
      };
      invidious-db = {
        image = "docker.io/library/postgres:14";
        hostname = "invidious-db";
        volumes = [
          "postgresdata:/var/lib/postgresql/data"
          "/home/philipp/nix-config/modules/nixos/virtualisation/podman/invidious/config/sql:/config/sql"
          "/home/philipp/nix-config/modules/nixos/virtualisation/podman/invidious/init-invidious-db.sh:/docker-entrypoint-initdb.d/init-invidious-db.sh"
        ];
        environmentFiles = [ /run/secrets/invidious-db ];
      };
    };
  };

}
