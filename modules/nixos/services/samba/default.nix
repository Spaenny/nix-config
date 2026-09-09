{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.samba;
in
{
  options.${namespace}.services.samba = {
    enable = mkEnableOption "Samba network share for OpenCloud user storage";

    shareName = mkOption {
      description = "Name of the Samba share.";
      type = types.str;
      default = "opencloud";
    };

    path = mkOption {
      description = "OpenCloud user storage path exposed through Samba.";
      type = types.path;
      default = "/data/opencloud/data/storage/users/users/5f2947ff-0cc3-44e5-886a-7ed07d70690b";
    };

    user = mkOption {
      description = "Authenticated Samba user allowed to access the share.";
      type = types.str;
      default = "philipp";
    };
  };

  config = mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = "blarm";
          security = "user";
          "map to guest" = "Bad User";
          "hosts allow" = "192.168.1.0/24";
          "hosts deny" = "0.0.0.0/0";
        };
        "${cfg.shareName}" = {
          path = cfg.path;
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = cfg.user;
          "force user" = "opencloud";
          "force group" = "opencloud";
          "create mask" = "0660";
          "directory mask" = "0770";
        };
      };
    };
  };
}
