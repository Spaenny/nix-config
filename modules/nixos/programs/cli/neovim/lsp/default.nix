{
  programs.nvf.settings.vim = {
    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
        default_format_opts.lsp_format = "fallback";
        format_on_save = {
          lsp_format = "fallback";
          timeout_ms = 500;
        };
      };
    };

    lsp = {
      enable = true;
      formatOnSave = true;
      inlayHints.enable = true;
      lightbulb.enable = true;
      lspkind.enable = true;
      mappings = {
        goToDefinition = "gd";
        goToDeclaration = "gD";
        goToType = "gy";
        listImplementations = "gI";
        listReferences = "gr";
        hover = "K";
        signatureHelp = "<leader>cs";
        renameSymbol = "<leader>rn";
        codeAction = "<leader>ca";
        format = "<leader>cf";
        openDiagnosticFloat = "<leader>cd";
        nextDiagnostic = "]d";
        previousDiagnostic = "[d";
        toggleFormatOnSave = "<leader>tf";
      };
    };

    languages = {
      enableTreesitter = true;
      bash.enable = true;
      fish.enable = true;
      go.enable = true;
      json.enable = true;
      markdown.enable = true;
      nix = {
        enable = true;
        format.type = [ "nixfmt" ];
      };
      python = {
        enable = true;
        format.type = [ "ruff" ];
      };
      rust = {
        enable = true;
        extensions.crates-nvim.enable = true;
      };
      toml.enable = true;
      yaml.enable = true;
      enableFormat = true;
    };
  };
}
