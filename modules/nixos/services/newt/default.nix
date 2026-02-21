{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.newt;
in
{
  options.${namespace}.services.newt = {
    enable = mkEnableOption "Newt";
  };

  config = mkIf cfg.enable {
    services.newt = {
      enable = true;
      environmentFile = "/run/secrets/aquarius-newt.env";
    };

    sops.secrets."aquarius-newt.env" = {
      format = "dotenv";
      sopsFile = ../../../../secrets/aquarius-newt.env;
    };

  };
}
