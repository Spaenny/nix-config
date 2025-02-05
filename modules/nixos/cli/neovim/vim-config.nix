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
    programs.nvf = {
      enable = true;
      settings = {
        vim = {
          viAlias = true;
          vimAlias = true;

          options = {
            tabstop = 2;
            shiftwidth = 2;
          };

          undoFile.enable = true;

          theme = {
            enable = true;
            name = "tokyonight";
            style = "night";
          };

          lsp.enable = true;
          statusline.lualine.enable = true;
          telescope.enable = true;
          autocomplete.nvim-cmp.enable = true;
          languages = {
            enableLSP = true;
            enableTreesitter = true;
            nix.enable = true;
          };
          filetree.neo-tree = {
            enable = true;
            setupOpts = {
            };
          };
          keymaps = [
            {
              key = "<C-n>";
              mode = [ "n" ];
              action = "<CMD>Neotree toggle<CR>";
              desc = "Toggles neo-tree";
            }
          ];
        };
      };
    };
  };

}
