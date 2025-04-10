{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.spectacle;
in
{
  options.${namespace}.desktop.spectacle = with types; {
    enable = mkBoolOpt false "Whether or not to enable spectacle config.";
  };

  config = mkIf cfg.enable {
    programs.plasma = {
      enable = true;
      spectacle.shortcuts.captureRectangularRegion = "Meta+Shift+S";
    };
  };

}
