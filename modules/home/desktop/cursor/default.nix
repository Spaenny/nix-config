{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.cursor;
in
{
  options.${namespace}.desktop.cursor = with types; {
    enable = mkBoolOpt false "Whether or not to enable custom cursor settings.";
  };

  config = mkIf cfg.enable {
    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.rose-pine-cursor;
      name = "BreezeX-RosePine-Linux";
      size = 32;
    };

  };

}
