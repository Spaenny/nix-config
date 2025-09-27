{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.apps.steam;
in
{
  options.${namespace}.apps.steam = with types; {
    enable = mkBoolOpt false "Whether or not to enable support for Steam.";
  };

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
      remotePlay.openFirewall = true;

      extraPackages = with pkgs; [
        steamtinkerlaunch
        proton-ge-bin
        awesome-flake.proton-ge-bin-9
      ];
    };

    programs.gamemode = {
      enable = true;
      settings = {
        general.renice = 10;
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started.'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended.'";
        };
      };
    };

    hardware.steam-hardware.enable = true;
  };
}
