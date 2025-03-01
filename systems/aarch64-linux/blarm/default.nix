{
  lib,
  pkgs,
  namespace,
  modulesPath,
  ...
}:
with lib.${namespace};
{
  imports = [
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
  networking.interfaces.end0 = {
    useDHCP = true;
    ipv4.addresses = [
      {
        address = "192.168.1.202";
        prefixLength = 32;
      }
    ];
  };
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

  # Disable detailed ddocumentation
  documentation.nixos.enable = false;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  snowfallorg.users.philipp = {
    create = true;
    admin = true;
    home = {
      enable = true;
    };
  };

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
  services.openssh = enabled;

  awesome-flake.services.caddy = enabled;
  awesome-flake.container.technitium = enabled;
  awesome-flake.container.invidious = enabled;
  awesome-flake.cli.neovim = enabled;
  awesome-flake.services.restic = enabled;
  awesome-flake.system.sops = enabled;

  environment.systemPackages = with pkgs; [
    git
  ];

  system.stateVersion = "24.11";

}
