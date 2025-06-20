{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.fwupd;
in
{
  options.${namespace}.system.fwupd = with types; {
    enable = mkBoolOpt false "Whether or not to enable fwupd.";
  };

  config = mkIf cfg.enable {
    services.fwupd.enable = true;
  };

}
