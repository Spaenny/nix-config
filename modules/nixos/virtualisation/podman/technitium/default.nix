{ lib, config, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.container.technitium;
in
{
  options.${namespace}.container.technitium = {
    enable = mkEnableOption "Technitium";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.technitium = {
      image = "technitium/dns-server";
      hostname = "blarm-dns";
      ports = [
        "192.168.1.202:5380:5380"
        "192.168.1.202:53:53"
        "[fd00:192:168:1::202]:53:53"
        "[fd00:192:168:1::202]:5380:5380"
      ];
      volumes = [ "config:/etc/dns" ];
    };
  };
}
