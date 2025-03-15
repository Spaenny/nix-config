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
    ./networking.nix
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

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


  awesome-flake = {
    services = {
      ssh = enabled;
      caddy = enabled;
      restic = enabled;
    };

    container = {
      technitium = enabled;
      invidious = enabled;
    };

    system.sops = enabled;
    cli.neovim = enabled;
  };

  environment.systemPackages = with pkgs; [
    git
  ];

  system.stateVersion = "24.11";

}
