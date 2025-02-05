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
  cfg = config.${namespace}.services.invidious;
in
{
  options.${namespace}.services.invidious = {
    enable = mkEnableOption "Invidious";
    domain = mkOption {
      type = types.string;
      default = "localhost";
      description = "Domain to use for absolute URLs";
    };
  };

  config = mkIf cfg.enable {
    services.invidious = {
      enable = true;
      domain = cfg.domain;
      extraSettingsFile = "/var/lib/invidious/settings.yml";
    };
  };
}
