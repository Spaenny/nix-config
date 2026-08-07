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
    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    programs.nvf = {
      defaultEditor = true;
      enable = true;
      settings = {
        vim = {
          enableLuaLoader = true;
          viAlias = true;
          vimAlias = true;

          globals = {
            mapleader = " ";
            maplocalleader = ",";
          };

          hideSearchHighlight = true;
          lineNumberMode = "relNumber";
          searchCase = "smart";

          options = {
            breakindent = true;
            completeopt = "menu,menuone,noselect";
            cursorline = true;
            tabstop = 2;
            shiftwidth = 2;
            expandtab = true;
            cursorlineopt = "screenline";
            ignorecase = true;
            scrolloff = 8;
            sidescrolloff = 8;
            signcolumn = "yes";
            smartcase = true;
            splitbelow = true;
            splitright = true;
            timeoutlen = 400;
            undolevels = 10000;
            updatetime = 250;
            wrap = false;
          };

          clipboard = {
            enable = true;
            registers = "unnamedplus";
          };

          undoFile.enable = true;

          keymaps = [
            {
              key = "<Esc>";
              mode = [ "n" ];
              action = "<cmd>nohlsearch<CR>";
              desc = "Clear search highlight";
            }
            {
              key = "<leader>w";
              mode = [ "n" ];
              action = "<cmd>write<CR>";
              desc = "Write buffer";
            }
            {
              key = "<leader>q";
              mode = [ "n" ];
              action = "<cmd>quit<CR>";
              desc = "Quit window";
            }
            {
              key = "<C-h>";
              mode = [ "n" ];
              action = "<C-w>h";
              desc = "Focus left window";
            }
            {
              key = "<C-j>";
              mode = [ "n" ];
              action = "<C-w>j";
              desc = "Focus lower window";
            }
            {
              key = "<C-k>";
              mode = [ "n" ];
              action = "<C-w>k";
              desc = "Focus upper window";
            }
            {
              key = "<C-l>";
              mode = [ "n" ];
              action = "<C-w>l";
              desc = "Focus right window";
            }
            {
              key = "<leader>e";
              mode = [ "n" ];
              action = "<cmd>Neotree toggle<CR>";
              desc = "Toggle file tree";
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
