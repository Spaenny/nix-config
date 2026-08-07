{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.networking.wireguard;
in
{
  options.${namespace}.networking.wireguard = with types; {
    enable = mkBoolOpt false "Whether or not to use wireguard-tools.";
  };

  config = mkIf cfg.enable {
    networking.wireguard = {
      enable = true;
    };
  };

}
