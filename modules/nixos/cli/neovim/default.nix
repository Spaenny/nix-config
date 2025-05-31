{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.cli.neovim;
in
{
  options.${namespace}.cli.neovim = with types; {
    enable = mkBoolOpt false "Whether or not to enable neovim.";
  };
  config = mkIf cfg.enable {
    environment.variables.EDITOR = "nvim";
    programs.nvf = {
      enable = true;
      settings = {
        vim = {
          viAlias = true;
          vimAlias = true;

          lineNumberMode = "relNumber";

          options = {
            tabstop = 2;
            shiftwidth = 2;
            cursorlineopt = "screenline";
          };

          undoFile.enable = true;

          keymaps = [
            {
              key = "<C-n>";
              mode = [ "n" ];
              action = "<CMD>Neotree toggle<CR>";
              desc = "Toggles neo-tree";
            }
            {
              key = "g=";
              mode = [ "n" ];
              action = "m'ggVG=''";
              desc = "Reindent code";
            }
          ];
        };
      };
    };
  };

}
