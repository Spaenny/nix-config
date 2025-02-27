{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.apps.thunderbird;
in
{
  options.${namespace}.apps.thunderbird = with types; {
    enable = mkBoolOpt false "Whether or not to enable Firefox.";
  };

  config = mkIf cfg.enable {
    programs.thunderbird = {
      enable = true;

      profiles."philipp" = {
        isDefault = true;
      };
    };
  };

}
