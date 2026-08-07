{
  programs.nvf.settings.vim.filetree.neo-tree = {
    enable = true;
    setupOpts = {
      auto_clean_after_session_restore = true;
      enable_cursor_hijack = true;
      git_status_async = true;
      hide_root_node = true;
      filesystem.hijack_netrw_behavior = "open_current";
    };
  };
}
