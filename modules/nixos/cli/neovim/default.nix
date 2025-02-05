{
  options,
  config,
  lib,
  pkgs,
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
        vim.viAlias = true;
        vim.vimAlias = true;
        vim.lsp.enable = true;
        vim.theme.enable = true;
        vim.theme.name = "tokyonight";
        vim.theme.style = "night";

        vim.languages.nix.enable = true;
        vim.statusline.lualine.enable = true;
        vim.telescope.enable = true;
        vim.autocomplete.nvim-cmp.enable = true;
        vim.languages.enableLSP = true;
        vim.languages.enableTreesitter = true;
        vim.options.tabstop = 2;
        vim.undoFile.enable = true;
        vim.options.shiftwidth = 2;
        vim.filetree.neo-tree = {
          enable = true;
          setupOpts = {
          };
        };
        vim.keymaps = [
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
}
