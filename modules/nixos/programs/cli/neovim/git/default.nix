{
  programs.nvf.settings.vim.git = {
    enable = true;

    gitsigns = {
      enable = true;
      mappings = {
        nextHunk = "]h";
        previousHunk = "[h";
        stageHunk = "<leader>hs";
        undoStageHunk = "<leader>hu";
        resetHunk = "<leader>hr";
        stageBuffer = "<leader>hS";
        resetBuffer = "<leader>hR";
        previewHunk = "<leader>hp";
        blameLine = "<leader>hb";
        diffThis = "<leader>hd";
        toggleBlame = "<leader>tb";
        toggleDeleted = "<leader>td";
      };
    };
  };
}
