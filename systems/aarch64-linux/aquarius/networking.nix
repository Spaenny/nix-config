{
  networking = {
    hostName = "aquarius";

    networkmanager.enable = false;
    dhcpcd.enable = false;
		useDHCP = false;

    firewall.enable = true;
  };

  systemd.network.enable = true;
  services.resolved.enable = true;

  systemd.network.networks."99-ignore-wg" = {
    matchConfig.Name = "wg*";
    networkConfig = {
      ConfigureWithoutCarrier = true;
    };
    linkConfig = {
      Unmanaged = "yes";
    };
  };

  systemd.network.networks."10-end0" = {
    matchConfig.Name = "end0";
    networkConfig.DHCP = "yes";

    dhcpV4Config = {
      UseDNS = true;
      UseRoutes = true;
    };

    dhcpV6Config = {
      UseDNS = true;
    };
  };

}
