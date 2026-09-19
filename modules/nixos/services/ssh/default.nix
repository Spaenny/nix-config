{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.ssh;
  defaultKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwUGxdwTgjc61VNh7QNfrrZwz5yHkJ6AGsRsgoDV3a4 mobile"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqbT8AdnS++ZoL7TYg2skQUvfWx29Iq+mEYv2Ok2QHb arbeit"
  ];
in
{
  options.${namespace}.services.ssh = {
    enable = mkBoolOpt false "OpenSSH";
    keys = mkOption {
      description = "Extra keys to add to config.";
      type = lib.types.listOf lib.types.str;
      default = defaultKeys;
    };
    passwordlessDeploy = mkBoolOpt false "Allow passwordless deploy-rs activation.";
  };

  config = mkIf cfg.enable {
    # Enable the OpenSSH daemon.
    services.openssh = enabled;

    users.users.philipp.openssh.authorizedKeys = {
      inherit (cfg)
        keys
        ;
    };

    security.sudo.extraRules = mkIf cfg.passwordlessDeploy [
      {
        users = [ "philipp" ];
        commands = map (command: {
          inherit command;
          options = [ "NOPASSWD" ];
        }) [
          # deploy-rs invokes wrappers in the activatable system. Keep the
          # canonical targets too, as sudo's symlink handling can vary.
          "/nix/store/*-activatable-nixos-system-*/activate-rs"
          "/nix/store/*-activatable-nixos-system-*/deploy-rs-activate"
          "/nix/store/*-activate-rs/activate-rs"
          "/nix/store/*-activate-path/deploy-rs-activate"
          "/run/current-system/sw/bin/rm /tmp/deploy-rs-canary-*"
          "/nix/store/*-coreutils-*/bin/rm /tmp/deploy-rs-canary-*"
        ];
      }
    ];
  };

}
