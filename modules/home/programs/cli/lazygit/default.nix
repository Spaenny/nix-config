{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.cli-apps.lazygit;
in
{
  options.${namespace}.cli-apps.lazygit = with types; {
    enable = mkBoolOpt false "Whether or not to enable lazygit.";
  };

  config = mkIf cfg.enable {
    programs.lazygit = {
      enable = true;
    };
  };

}
