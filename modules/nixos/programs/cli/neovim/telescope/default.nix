{
  programs.nvf.settings.vim.telescope = {
    enable = true;
    setupOpts.defaults = {
      layout_config = {
        height = 0.9;
        horizontal.preview_width = 0.55;
        width = 0.9;
      };
      path_display = [ "smart" ];
      file_ignore_patterns = [
        "node_modules"
        "%.git/"
        "dist/"
        "build/"
        "target/"
        "result/"
        ".direnv/"
      ];
    };
  };
}
