{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.newt;
  sopsCfg = config.${namespace}.system.sops;
in
{
  options.${namespace}.services.newt = {
    enable = mkEnableOption "Newt";
  };

  config = mkIf cfg.enable {
    ${namespace}.system.sops = enabled;

    services.newt = {
      enable = true;
      environmentFile = config.sops.secrets."aquarius-newt.env".path;
    };

    sops.secrets."aquarius-newt.env" = mkSopsDotenvSecret sopsCfg.secretsDir "aquarius-newt.env";

  };
}
