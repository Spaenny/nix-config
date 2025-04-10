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
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

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

  users.users.philipp = {
    isNormalUser = true;
    description = "Philipp Böhm";
    extraGroups = [
      "wheel"
      "caddy"
    ];
  };

  snowfallorg.users.philipp = {
    create = true;
    admin = true;
    home = {
      enable = true;
    };
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
