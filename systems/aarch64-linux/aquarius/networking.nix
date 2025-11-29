{
  networking = {
    hostName = "aquarius";
    networkmanager.enable = false;
    dhcpcd.enable = true;

    interfaces.end0.useDHCP = true;

    firewall = {
      enable = true;
      allowedUDPPorts = [ 51820 ];
    };

    wireguard = {
      enable = true;
      interfaces."wg0" = {
        ips = [
          "192.168.100.10/24"
          "fd00:100::10/64"
        ];
        listenPort = 51820;
        mtu = 1400;
        privateKeyFile = "/run/secrets/privateKey";
        peers = [
          {
            publicKey = "ylsjhpKiq3B6Kv4q2uiHXUJpyxY2b1DOAlGc/FWdflQ=";
            presharedKeyFile = "/run/secrets/presharedKey";
            allowedIPs = [
              "192.168.100.1/32"
              "fd00:100::1/128"
            ];
            endpoint = "neuruppin.boehm.sh:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };

  sops.secrets = {
    privateKey = {
      sopsFile = ../../../secrets/aquarius-wg.yaml;
      key = "privateKey";
    };

    presharedKey = {
      sopsFile = ../../../secrets/aquarius-wg.yaml;
      key = "presharedKey";
    };
  };

}
