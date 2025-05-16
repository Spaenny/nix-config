{
  pkgs,
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        consoleMode = "max";
      };
    };
  };

  virtualisation.libvirtd.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "bodenheizung";

  users.users.philipp = {
    isNormalUser = true;
    description = "Philipp Böhm";
    extraGroups = [
      "wheel"
      "caddy"
      "audio"
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
    cli = {
      neovim = enabled;
      eza = enabled;
      nh = enabled;
      wireguard = enabled;
    };

    apps = {
      steam = enabled;
    };

    desktop.plasma = enabled;
    hardware.audio = enabled;

    services = {
      btrfs = enabled;
    };

    system = {
      tmpfs = enabled;
      fonts = {
        enable = true;
        emoji = true;
      };
      gstreamer = enabled;
      gnupg = enabled;
    };
  };

  # Set your time zone
  time.timeZone = "Europe/Berlin";

  # Select internationalistation properties
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "de_DE.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LANGUAGE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
    };
  };

  environment.etc.crypttab = {
    mode = "0600";
    text = ''
      ssd /dev/disk/by-uuid/44afe46a-4ca4-4ef2-a603-a47520eebff1 /root/.crypt-me
    '';
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
