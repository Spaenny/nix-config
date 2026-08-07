{
  programs.nvf.settings.vim.binds.whichKey = {
    enable = true;
    setupOpts = {
      notify = false;
      preset = "modern";
    };
    register = {
      "<leader>c" = "Code";
      "<leader>f" = "Find";
      "<leader>h" = "Git hunk";
      "<leader>r" = "Refactor";
      "<leader>t" = "Toggle";
    };
  };
}
