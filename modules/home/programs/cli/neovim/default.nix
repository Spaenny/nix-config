{
  lib,
  config,
  osConfig ? { },
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optional;

  cfg = config.${namespace}.cli.neovim;
  # The user profile comes first in PATH, so a plain neovim here would shadow
  # the configured nvf one from the system.
  systemNeovim = osConfig.programs.nvf.enable or false;
in
{
  options.${namespace}.cli.neovim = {
    enable = mkEnableOption "Neovim";
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.less ] ++ optional (!systemNeovim) pkgs.neovim;

      sessionVariables = {
        EDITOR = "nvim";
      };

      shellAliases = {
        vimdiff = "nvim -d";
      };
    };

    xdg.configFile = {
      "dashboard-nvim/.keep".text = "";
    };
  };

}
