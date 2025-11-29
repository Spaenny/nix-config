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
  cfg = config.${namespace}.desktop.panel;
in
{
  options.${namespace}.games.runelite = with types; {
    enable = mkBoolOpt false "Whether or not to enable the runelite client for runescape.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      runelite
      bolt-launcher
    ];
  };
}
