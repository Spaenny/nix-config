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
      llama-server = {
        enable = true;
        host = "0.0.0.0";
        hf = "ggml-org/gpt-oss-20b-GGUF:MXFP4";
        alias = "gpt-oss-20b";
        contextLength = 65536;
        # ~11.3 GiB weights + ~0.8 GiB KV fit into the 16 GiB VRAM, so all
        # layers (incl. the MoE experts) run on the GPU.
        gpuLayers = 999;
        # f16 KV cache: safest choice for gpt-oss and still fits easily.
        cacheTypeK = "f16";
        cacheTypeV = "f16";
        extraSettings = {
          temp = 1.0;
          top-p = 0.95;
          top-k = 20;
          min-p = 0;
        };
      };
      lact = {
        enable = true;
        fanCurve = "1200:65,2000:85,3000:100";
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
