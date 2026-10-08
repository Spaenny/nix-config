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
  cfg = config.${namespace}.apps.photocraft;
in
{
  options.${namespace}.apps.photocraft = with types; {
    enable = mkBoolOpt false "Whether or not to enable photocraft.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      awesome-flake.photocraft
    ];
  };
}
