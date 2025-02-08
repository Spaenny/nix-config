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
  cfg = config.${namespace}.apps.chatterino;
in
{
  options.${namespace}.apps.chatterino = with types; {
    enable = mkBoolOpt false "Whether or not to enable kitty.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.chatterino2 ];
  };

}
