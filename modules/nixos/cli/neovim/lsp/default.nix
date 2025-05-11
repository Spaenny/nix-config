{
  programs.nvf.settings.vim = {
    lsp.enable = true;
    languages = {
      enableTreesitter = true;
      nix.enable = true;
      nix.format.type = "nixfmt";
      bash.enable = true;
      go.enable = true;
      rust.enable = true;
      python.enable = true;
      enableFormat = true;
    };
  };

}
