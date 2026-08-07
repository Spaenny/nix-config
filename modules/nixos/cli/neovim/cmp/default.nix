{
  programs.nvf.settings.vim.autocomplete.nvim-cmp = {
    enable = true;
    setupOpts.completion.completeopt = "menu,menuone,noselect";
    mappings = {
      complete = "<C-Space>";
      confirm = "<CR>";
      next = "<Tab>";
      previous = "<S-Tab>";
      close = "<C-e>";
    };
  };
}
