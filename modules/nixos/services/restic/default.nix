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
  sopsCfg = config.${namespace}.system.sops;
in
{
  options.${namespace}.services.restic = {
    enable = mkBoolOpt false "Restic";
  };

  config = mkIf cfg.enable {
    ${namespace}.system.sops = enabled;

    sops.secrets.restic_url = mkSopsSecret sopsCfg.secretsDir "blarm-restic.yaml" {
      format = "yaml";
      key = "restic/url";
    };
    sops.secrets.restic_password = mkSopsSecret sopsCfg.secretsDir "blarm-restic.yaml" {
      format = "yaml";
      key = "restic/password";
    };
    services.restic.backups = {
      borgbase = {
        initialize = true;
        exclude = [
          "/home/*/.cache"
        ];
        passwordFile = config.sops.secrets.restic_password.path;
        repositoryFile = config.sops.secrets.restic_url.path;
        paths = [
          "/home"
          "/var/lib"
          "/data"
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
