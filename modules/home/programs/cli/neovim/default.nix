{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.cli.neovim;
in
{
  options.${namespace}.cli.neovim = {
    enable = mkEnableOption "Neovim";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        less
        plusultra.neovim
      ];

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
