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
  cfg = config.${namespace}.apps.spotify;
in
{
  options.${namespace}.apps.spotify = with types; {
    enable = mkBoolOpt false "Whether or not to enable spotify.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      librespot
      spotify-qt
    ];
  };

}
