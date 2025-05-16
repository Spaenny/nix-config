{
  lib,
  modulesPath,
  namespace,
  ...
}:
with lib.${namespace};
{
  imports = [ (modulesPath + "/virtualisation/proxmox-lxc.nix") ];

  documentation.man.generateCaches = false;

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

    system.tmpfs = true;
  };

  environment.systemPackages = with pkgs; [
    git
  ];

  # Set your time zone
  time.timeZone = "Europe/Berlin";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
