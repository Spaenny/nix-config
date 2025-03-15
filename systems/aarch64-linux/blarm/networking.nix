{
  networking = {
    hostName = "blarm";
    firewall.enable = false;
    networkmanager.enable = false;
    dhcpcd.enable = true;
    defaultGateway.address = "192.168.1.1";
    interfaces.end0 = {
      useDHCP = true;
      ipv4.addresses = [
        {
          address = "192.168.1.251";
          prefixLength = 32;
        }
        {
          address = "192.168.1.202";
          prefixLength = 32;
        }
      ];
      ipv6.addresses = [
        {
          address = "fd00:192:168:1::202";
          prefixLength = 64;
        }
        {
          address = "fd00:192:168:1::251";
          prefixLength = 64;
        }
      ];
    };
  };

}
