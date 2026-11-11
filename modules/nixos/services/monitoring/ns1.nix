{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.monitoring;
  sopsCfg = config.${namespace}.system.sops;
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkSopsSecret;

  # ns1.boehm.sh is only reachable for scraping through its WireGuard network.
  ns1Address = "10.200.0.1";

  mkWgSecret =
    key:
    mkSopsSecret sopsCfg.secretsDir "blarm-wireguard-ns1.yaml" {
      inherit key;
      mode = "0400";
      # blarm uses networkd, which loads the keys as credentials at start.
      restartUnits = [ "systemd-networkd.service" ];
    };
in
{
  config = mkIf cfg.enable {
    sops.secrets = {
      "wireguard/ns1/private-key" = mkWgSecret "private_key";
      "wireguard/ns1/preshared-key" = mkWgSecret "preshared_key";
    };

    # Outbound-only client: no listen port, nothing forwarded, only ns1 routed.
    networking.wireguard.interfaces.wg-ns1 = {
      ips = [ "10.200.0.150/32" ];
      privateKeyFile = config.sops.secrets."wireguard/ns1/private-key".path;
      peers = [
        {
          publicKey = "Rz54om8o0G2ZXpcnPFLnQPi99ABp5mNIzdji3Oi7nF8=";
          presharedKeyFile = config.sops.secrets."wireguard/ns1/preshared-key".path;
          allowedIPs = [ "${ns1Address}/32" ];
          endpoint = "ns1.boehm.sh:51820";
          persistentKeepalive = 25;
        }
      ];
    };

    services.prometheus.scrapeConfigs = [
      {
        job_name = "ns1-node";
        static_configs = [
          {
            targets = [ "${ns1Address}:9100" ];
            labels.instance = "ns1.boehm.sh";
          }
        ];
      }
      {
        job_name = "ns1-powerdns";
        static_configs = [
          {
            targets = [ "${ns1Address}:8088" ];
            labels.instance = "ns1.boehm.sh";
          }
        ];
      }
    ];
  };
}
