{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.gnupg;
in
{
  options.${namespace}.system.gnupg = with types; {
    enable = mkBoolOpt false "Whether or not to enable gnupg.";
  };

  config = mkIf cfg.enable {
    services.pcscd.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
      pinentryPackage = pkgs.pinentry-qt;
    };
  };

}
