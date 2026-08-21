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
  ];

  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    initrd.kernelModules = [ "amdgpu" ];
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = [
      "amd_pstate=active"
      "split_lock_detect=off"
    ];
    kernel.sysctl."vm.max_map_count" = 2147483642;
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        consoleMode = "max";
      };
    };
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

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
      "audio"
      "dialout"
      "libvirtd"
    ];
  };

  services.teamviewer.enable = true;
  services.flatpak.enable = true;
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0029", TEST=="power/control", ATTR{power/control}="on"
  '';

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  ${namespace} = {
    cli = {
      neovim = enabled;
      eza = enabled;
      nh = enabled;
    };

    networking.wireguard = enabled;

    games = {
      steam = enabled;
    };

    desktop.plasma = enabled;
    hardware.audio = enabled;

    services = {
      btrfs = enabled;
      ssh = enabled;
      printer = enabled;
    };

    system = {
      tmpfs = enabled;
      fwupd = enabled;
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
