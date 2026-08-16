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
  cfg = config.${namespace}.apps.signal-desktop;
in
{
  options.${namespace}.apps.signal-desktop = with types; {
    enable = mkBoolOpt false "Whether or not to enable signal-desktop.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      signal-desktop
    ];
  };

}
