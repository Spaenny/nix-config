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
  cfg = config.${namespace}.container.invidious;
in
{
  options.${namespace}.container.invidious = {
    enable = mkEnableOption "Invidious";
  };

  config = mkIf cfg.enable {
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
        volumes = [
          "/home/philipp/nix-config/modules/nixos/virtualisation/podman/invidious/config/config.yml:/invidious/config/config.yml"
        ];
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
        environmentFiles = [
          /home/philipp/nix-config/modules/nixos/virtualisation/podman/invidious/config/db.env
        ];
      };
    };
  };

}
