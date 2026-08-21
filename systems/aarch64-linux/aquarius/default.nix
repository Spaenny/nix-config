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
  boot.zfs.forceImportRoot = false;

  nix.settings = {
    trusted-users = [ "philipp" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Disable detailed documentation
  documentation = {
    nixos.enable = false;
    man.cache.enable = false;
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.philipp = {
    isNormalUser = true;
    description = "Philipp Böhm";
    extraGroups = [
      "wheel"
    ];
  };

  services = {
    openssh.settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };

    cron = enabled;
  };

  ${namespace} = {
    services = {
      ssh = enabled;
      technitium-dns-server = enabled;
    };

    system.sops = enabled;
    cli.neovim = enabled;
  };

  environment.systemPackages = with pkgs; [
    git
  ];

  system.stateVersion = "24.11";

}
