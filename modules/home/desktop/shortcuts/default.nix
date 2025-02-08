{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.hotkeys;
in
{
  options.${namespace}.desktop.hotkeys = with types; {
    enable = mkBoolOpt false "Whether or not to enable custom shortcuts.";
  };

  config = mkIf cfg.enable {
    programs.plasma = {
      enable = true;
      shortcuts.kwin = {
        "Window Close" = [
          "Meta+Shift+Q"
          "Alt+F4"
        ];
      };
    };
  };

}
