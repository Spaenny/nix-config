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
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  nix.settings = {
    trusted-users = [ "philipp" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  networking.hostName = "blarm";

  # Disable documentation
  documentation = {
    nixos.enable = false;
    man.generateCaches = false;
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
      cinny = enabled;
      ente-auth = enabled;
      restic = enabled;
      linkwarden = enabled;
      forgejo = enabled;
      searxng = enabled;
      #immich = enabled; # We wait for the proper version to be in nixpkgs
      paperless = enabled;
      syncthing = enabled;
    };

    #container.invidious = enabled;

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
