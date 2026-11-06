{
  lib,
  pkgs,
  modulesPath,
  namespace,
  ...
}:
with lib.${namespace};
let
  # PVE generates systemd-networkd files for the container's uplink interface
  # (net0 on both dns-1 and dns-2) with IPv6AcceptRA=false, which blocks SLAAC
  # of a global IPv6 address. A drop-in overrides just that setting, leaves the
  # static addresses and gateways PVE manages untouched, and survives PVE
  # rewriting the base files on container config changes.
  acceptRaConf = pkgs.writeText "10-accept-ra.conf" ''
    [Network]
    IPv6AcceptRA=true
  '';
in
{
  imports = [ (modulesPath + "/virtualisation/proxmox-lxc.nix") ];

  documentation.man.cache.enable = false;

  nix.settings = {
    trusted-users = [ "philipp" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  users.users.philipp = {
    isNormalUser = true;
    description = "Philipp Böhm";
    extraGroups = [
      "wheel"
    ];
  };

  services.resolved = {
    enable = true;
  };

  ${namespace} = {
    services = {
      ssh = {
        enable = true;
        passwordlessDeploy = true;
      };
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

    system.tmpfs = enabled;
  };

  environment.etc = {
    "systemd/network/net0.network.d/10-accept-ra.conf".source = acceptRaConf;
  };

  # environment.etc files are not covered by the networkd module's own
  # triggers, so reload systemd-networkd when the drop-ins change.
  systemd.services.systemd-networkd.reloadTriggers = [ acceptRaConf ];

  environment.systemPackages = with pkgs; [
    git
  ];

  # Set your time zone
  time.timeZone = "Europe/Berlin";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
