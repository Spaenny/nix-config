{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

with lib;
with lib.${namespace};

let
  cfg = config.${namespace}.apps.zed-editor;

  # Local llama.cpp server (llama-server, see services.llama-server).
  # Zed auto-discovers models from the server's /props endpoint.
  settings = {
    language_models = {
      "llama.cpp" = {
        api_url = "http://localhost:8080";
        auto_discover = true;
      };
      openai_compatible.cortecs = {
        api_url = "https://api.cortecs.ai/v1";
        available_models = [
          {
            name = "glm-5.3-flash";
            display_name = "GLM 5.3 Flash";
            max_tokens = 1048576;
          }
        ];
      };
    };

    agent = {
      default_model = {
        provider = "cortecs";
        model = "glm-5.3-flash";
      };

      # Allow agent terminal commands to run outside the sandbox
      sandbox_permissions = {
        allow_unsandboxed = true;
      };
    };

    # Enable vim mode by default
    vim_mode = true;
  };
in
{
  options.${namespace}.apps.zed-editor = with types; {
    enable = mkBoolOpt false "Whether or not to enable zed-editor.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bubblewrap
      go
      gopls
      nil
      nixd
      zed-editor
    ];

    # Configure Zed settings
    xdg.configFile."zed/settings.json".text = builtins.toJSON settings;
  };
}
