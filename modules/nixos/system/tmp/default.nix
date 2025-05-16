{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.tmpfs;
in
{
  options.${namespace}.system.tmpfs = with types; {
    enable = mkBoolOpt false "Whether or not to use tmpfs for /tmp.";
  };

  config = mkIf cfg.enable {
    boot.tmp = {
      cleanOnBoot = true;
      tmpfsSize = "50%";
      useTmpfs = true;
    };
  };

}
