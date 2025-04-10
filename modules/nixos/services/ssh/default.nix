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
  };

  config = mkIf cfg.enable {
    # Enable the OpenSSH daemon.
    services.openssh = enabled;

    users.users.philipp.openssh.authorizedKeys = {
      inherit (cfg)
        keys
        ;
    };
  };

}
