{
  modulesPath,
  inputs,
  ...
}:
{
  imports = with inputs.nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  networking.hostName = "blarm"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.defaultGateway.address = "192.168.1.1";
  networking.defaultGateway.interface = "end0";
  networking.interfaces.end0.ipv4.addresses = [
    {
      address = "192.168.1.202";
      prefixLength = 32;
    }
  ];
  networking.interfaces.end0.ipv6.addresses = [
    {
      address = "fd00:192:168:1::202";
      prefixLength = 64;
    }
    {
      address = "fd00:192:168:1::251";
      prefixLength = 64;
    }
  ];
  networking.firewall.enable = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.philipp = {
    isNormalUser = true;
    description = "Philipp Böhm";
    extraGroups = [
      "wheel"
      "caddy"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwUGxdwTgjc61VNh7QNfrrZwz5yHkJ6AGsRsgoDV3a4 philipp-mobile"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqbT8AdnS++ZoL7TYg2skQUvfWx29Iq+mEYv2Ok2QHb arbeit"
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  awesome-flake.services.caddy.enable = true;
  awesome-flake.container.technitium.enable = true;
  awesome-flake.container.invidious.enable = true;
  awesome-flake.cli.neovim.enable = true;

  system.stateVersion = "24.11";

}
