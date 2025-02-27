{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.apps.mpv;
in
{
  options.${namespace}.apps.mpv = with types; {
    enable = mkBoolOpt false "Whether or not to enable mpv.";
  };

  config = mkIf cfg.enable {
    programs.mpv = {
      enable = true;
    };
  };

}
