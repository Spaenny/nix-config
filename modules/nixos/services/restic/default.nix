{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.restic;
in
{
  options.${namespace}.services.restic = {
    enable = mkBoolOpt false "Restic";
  };

  config = mkIf cfg.enable {
    sops.secrets.restic_url = {
      format = "yaml";
      sopsFile = ../../../../secrets/blarm-restic.yaml;
      key = "restic/url";
    };
    sops.secrets.restic_password = {
      format = "yaml";
      sopsFile = ../../../../secrets/blarm-restic.yaml;
      key = "restic/password";
    };
    services.restic.backups = {
      borgbase = {
        initialize = true;
        exclude = [ "/home/*/.cache" ];
        passwordFile = "/run/secrets/restic_password";
        repositoryFile = "/run/secrets/restic_url";
        paths = [
          "/home"
          "/var/lib/"
        ];
        timerConfig = {
          OnCalendar = "00:10";
          RandomizedDelaySec = "1h";
        };
      };
    };

    environment.systemPackages = with pkgs; [ restic ];
  };
}
