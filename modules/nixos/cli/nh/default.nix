{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.cli.nh;
in
{
  options.${namespace}.cli.nh = with types; {
    enable = mkBoolOpt false "Whether or not to use nh.";
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "${config.flakeRoot}";
    };
  };

}
