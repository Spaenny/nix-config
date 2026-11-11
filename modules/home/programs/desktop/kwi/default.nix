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
  cfg = config.${namespace}.apps.kwi;

  # Tokyo Night (night), same palette as kitty-themes' tokyo_night_night.
  tokyoNight = {
    background = "1a1b26";
    foreground = "c0caf5";
    normal = [
      "15161e"
      "f7768e"
      "9ece6a"
      "e0af68"
      "7aa2f7"
      "bb9af7"
      "7dcfff"
      "a9b1d6"
    ];
    bright = [
      "414868"
      "ff899d"
      "9fe044"
      "faba4a"
      "8db0ff"
      "c7a9ff"
      "a4daff"
      "c0caf5"
    ];
  };

  rgb =
    hex:
    concatMapStringsSep "," (i: toString (fromHexString (substring i 2 hex))) [
      0
      2
      4
    ];

  # Konsole colorscheme format, which kwi reads from kwi/color-schemes/stock.
  tokyoNightScheme = generators.toINI { } (
    {
      General.Description = "Tokyo Night";
      Background.Color = rgb tokyoNight.background;
      BackgroundIntense.Color = rgb tokyoNight.background;
      Foreground.Color = rgb tokyoNight.foreground;
      ForegroundIntense.Color = rgb tokyoNight.foreground;
    }
    // listToAttrs (
      imap0 (i: c: nameValuePair "Color${toString i}" { Color = rgb c; }) tokyoNight.normal
      ++ imap0 (i: c: nameValuePair "Color${toString i}Intense" { Color = rgb c; }) tokyoNight.bright
    )
  );

  defaultSettings = {
    Appearance = {
      ColorScheme = "konsole:TokyoNight.colorscheme";
    };
    Terminal = {
      CursorStyle = "beam";
    };
    Behavior = {
      ConfirmCloseRunning = false;
      CopyOnSelect = true;
    };
  };
  defaultFont = {
    name = "Hack Nerd Font Mono";
    package = pkgs.nerd-fonts.hack;
    size = 12;
  };
in
{
  options.${namespace}.apps.kwi = with types; {
    enable = mkBoolOpt false "Whether or not to enable kwi.";
    settings = mkOpt attrs defaultSettings "Groups and keys to write to kwiterminalrc.";
    font = mkOpt attrs defaultFont "Customize default font settings.";
    plasma.enable = mkBoolOpt false "Whether to enable plasma configs for kwi.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.${namespace}.kwi
      cfg.font.package
    ]; # fc-cache -fv clear fontconfig when error

    xdg.dataFile."kwi/color-schemes/stock/TokyoNight.colorscheme".text = tokyoNightScheme;

    # Written through plasma-manager instead of a store symlink, so kwi's own
    # settings dialog can still save to the file.
    programs.plasma = mkMerge [
      {
        configFile.kwiterminalrc = recursiveUpdate {
          Appearance = {
            UseSystemFont = false;
            FontFamily = cfg.font.name;
            FontPointSize = cfg.font.size;
          };
        } cfg.settings;
      }
      (mkIf cfg.plasma.enable {
        enable = true;
        hotkeys.commands."launch-kwi" = {
          name = "Launch kwi";
          key = "Meta+Return";
          command = "kwi";
        };
      })
    ];
  };

}
