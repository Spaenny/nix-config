{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.cli.wireguard;
in
{
  options.${namespace}.cli.wireguard = with types; {
    enable = mkBoolOpt false "Whether or not to use wiguard-tools.";
  };

  config = mkIf cfg.enable {
    networking.wireguard = {
      enable = true;
    };
  };

}
