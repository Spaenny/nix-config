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
  cfg = config.${namespace}.cli.eza;
in
{
  options.${namespace}.cli.eza = with types; {
    enable = mkBoolOpt false "Whether or not to use eza.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.eza ];
  };

}
