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

  networking = {
    hostName = "bodenheizung";
  };

  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [ ];
  };

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

  # Unlocks the amdgpu overdrive sysfs interface (pp_od_clk_voltage / gpu_od),
  # required for LACT fan curve and voltage offset control. Takes effect on
  # reboot.
  hardware.amdgpu.overdrive.enable = true;

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

    desktop.plasma = {
      enable = true;
      remoteDesktop = enabled;
    };
    hardware = {
      apple = enabled;
      audio = enabled;
    };

    services = {
      btrfs = enabled;
      ssh = enabled;
      printer = enabled;
      netbird = {
        enable = true;
        setupKeySecret = "bodenheizung-netbird.key";
      };
      llama-server = {
        enable = true;
        host = "0.0.0.0";
        hf = "ConwayResearch/Underdog-Saluki-27B-1.0:IQ2-mix";
        alias = "underdog-saluki-27b";
        contextLength = 65536;
        # ~7.4 GiB weights (IQ2-mix) + mmproj leave room next to the desktop
        # on the 16 GiB card: quantized KV cache is still required to hold the
        # 64k context, and layer offloading stays automatic so llama-server
        # fits as many layers into VRAM as possible instead of OOMing.
        cacheTypeK = "q4_0";
        cacheTypeV = "q4_0";
        extraSettings = {
          # Recommended sampling for Qwen thinking models.
          temp = 0.6;
          top-p = 0.95;
          top-k = 20;
          min-p = 0;
        };
      };
      lact = {
        enable = true;
        # vendor:device-subvendor:subdevice-pciaddress, from `lact cli list`
        gpuId = "1002:7550-1025:187A-0000:28:00.0";
        fanCurve = "1200:65,2000:85,3000:100";
        # VDDGFX undervolt in mV; hardware range is -200 to 0.
        voltageOffset = -100;
      };
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
      nix-ld = enabled;
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
