{
  lib,
  pkgs,
  namespace,
  ...
}:
with lib.${namespace};
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
  ];

  boot.loader = {
    grub.enable = false;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.philipp = {
    isNormalUser = true;
    description = "Philipp Böhm";
    extraGroups = [
      "wheel"
    ];
  };

  awesome-flake = {
    services = {
      ssh = enabled;
      technitium-dns-server = {
        enable = true;
        openFirewall = true;
      };
    };

    cli = {
      neovim = enabled;
      eza = enabled;
      nh = enabled;
    };
  };

  # Set your time zone
  time.timeZone = "Europe/Berlin";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
