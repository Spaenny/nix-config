{
  lib,
  pkgs,
  namespace,
  modulesPath,
  ...
}:
with lib.${namespace};
{
  imports = [ (modulesPath + "/virtualisation/proxmox-lxc.nix") ];

  nix.settings = {
    trusted-users = [ "philipp" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  networking = {
    hostName = "blarm";
    nameservers = [
      "192.168.5.100"
      "192.168.5.200"
      "fdf3:567b:734c:5::100"
      "fdf3:567b:734c:5::200"
    ];
  };

  # Disable documentation
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
      "caddy"
    ];
  };

  ${namespace} = {
    services = {
      ssh = enabled;
      cinny = enabled;
      ente-auth = enabled;
      ente-server = enabled;
      restic = enabled;
      linkwarden = enabled;
      forgejo = enabled;
      kanidm = enabled;
      opencloud = enabled;
      samba = enabled;
      zabbix = enabled;
      searxng = enabled;
      #immich = enabled; # We wait for the proper version to be in nixpkgs
      paperless = enabled;
      syncthing = enabled;
    };

    system = {
      sops = enabled;
      tmpfs = enabled;
    };

    cli.neovim = enabled;
  };


  environment.systemPackages = with pkgs; [
    git
  ];

  system.stateVersion = "24.11";

}
