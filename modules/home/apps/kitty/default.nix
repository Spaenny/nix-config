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
  cfg = config.${namespace}.apps.kitty;
  defaultSettings = {
    confirm_os_window_close = 0;
    mouse_hide_wait = "-1.0";
    dynamic_background_opacity = true;
    editor = "nvim";
    term = "xterm-256color";
    adjust_line_height = 3;
    copy_on_select = "clipboard";
    cursor_shape = "Beam";
  };
  defaultFont = {
    name = "Hack Nerd Font Mono";
    package = pkgs.nerdfonts;
    size = 12;
  };
in
{
  options.${namespace}.apps.kitty = with types; {
    enable = mkBoolOpt false "Whether or not to enable kitty.";
    settings = mkOpt attrs defaultSettings "Settings to apply to the profile.";
    font = mkOpt attrs defaultFont "Customize default font settings.";
    plasma.enable = mkBoolOpt false "Whether to enable plasma configs for kitty.";
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      themeFile = "Dracula";
      inherit (cfg) font settings;
    };

    programs.plasma = mkIf cfg.plasma.enable {
      enable = true;
      hotkeys.commands."launch-kitty" = {
        name = "Launch kitty";
        key = "Meta+Return";
        command = "kitty";
      };
    };
  };

}
