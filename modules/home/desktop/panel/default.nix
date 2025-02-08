{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.panel;
in
{
  options.${namespace}.desktop.panel = with types; {
    enable = mkBoolOpt false "Whether or not to enable custom panel settings.";
  };

  config = mkIf cfg.enable {
    programs.plasma = {
      enable = true;
      panels = [
        {
          location = "top";
          floating = true;
          screen = [
            1
            3
          ];
          widgets = [
            {
              kickoff = {
                sortAlphabetically = true;
                icon = "nix-snowflake-white";
              };
            }
            "org.kde.plasma.pager"
            {
              iconTasks = {
                launchers = [
                  "applications:org.kde.dolphin.desktop"
                  "applications:kitty.desktop"
                  "applications:librewolf.desktop"
                ];
              };
            }
            "org.kde.plasma.marginsseparator"
            "org.kde.plasma.systemtray"
            {
              digitalClock = {
                calendar.firstDayOfWeek = "monday";
                time.format = "24h";
              };
            }
            "org.kde.plasma.showdesktop"
          ];
        }
      ];
    };
  };

}
