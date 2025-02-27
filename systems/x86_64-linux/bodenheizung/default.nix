{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  virtualisation.libvirtd.enable = true;

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "bodenheizung";

  snowfallorg.users.philipp = {
    create = true;
    admin = true;
    home = {
      enable = true;
    };
  };

  awesome-flake = {
    cli = {
      neovim.enable = true;
      eza.enable = true;
    };

    apps = {
      steam.enable = true;
    };

    desktop.plasma.enable = true;
    hardware.audio.enable = true;

    services = {
      btrfs.enable = true;
    };

    system.fonts.enable = true;
    system.fonts.emoji = true;
    system.gnupg.enable = true;
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
