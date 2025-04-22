{
	networking = {
		hostName = "dns-1";
		firewall.enable = false;
		networkmanager.enable = false;
		dhcpcd.enable = false;
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
		defaultGateway.address = "192.168.5.1";
		interfaces.ens18 = {
			ipv4.addresses = [
			{
				address = "192.168.5.100";
				prefixLength = 24;
			}
			];
			ipv6.addresses = [
			{
				address = "fd00:192:168:5::100";
				prefixLength = 64;
			}
			];
		};
	};

}
