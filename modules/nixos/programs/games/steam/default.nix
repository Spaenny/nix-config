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
  cfg = config.${namespace}.games.steam;
in
{
  options.${namespace}.games.steam = with types; {
    enable = mkBoolOpt false "Whether or not to enable support for Steam.";
  };

  config = mkIf cfg.enable {
    programs = {
      steam = {
        enable = true;
        extest.enable = true;
        gamescopeSession.enable = true;
        protontricks.enable = true;
        remotePlay.openFirewall = true;

        extraCompatPackages = with pkgs; [
          proton-ge-bin
          steamtinkerlaunch
        ];

        extraPackages = with pkgs; [
          mangohud
        ];
      };

      gamescope = {
        capSysNice = true;
        enableWsi = true;
      };

      gamemode = {
        enable = true;
        settings = {
          general.renice = 10;
          custom = {
            start = "${pkgs.libnotify}/bin/notify-send 'GameMode started.'";
            end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended.'";
          };
        };
      };
    };

    hardware.steam-hardware.enable = true;
  };
}
