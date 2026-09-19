{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.searxng;
  sopsCfg = config.${namespace}.system.sops;
  aiAnswersPlugin = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/cra88y/ai-answers-searxng/616b5dc93e7e203c1a94d28ca62a963a25451e27/ai_answers.py";
    hash = "sha256-xJHgbIiZf6IYh+A+uYOK7Gg1vsjxTgc1Gk+UT2X0O1M=";
  };
  searxPackage = pkgs.searxng.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      install -Dm644 ${aiAnswersPlugin} \
        "$out/${pkgs.python3.sitePackages}/searx/plugins/ai_answers.py"
    '';
  });
  aiAnswersEnvironment =
    {
      LLM_PROVIDER = cfg.aiAnswers.provider;
    }
    // optionalAttrs (cfg.aiAnswers.model != null) { LLM_MODEL = cfg.aiAnswers.model; }
    // optionalAttrs (cfg.aiAnswers.url != null) { LLM_URL = cfg.aiAnswers.url; };
in
{
  options.${namespace}.services.searxng = with types; {
    enable = mkBoolOpt false "SearXNG";

    domain = mkOption {
      description = "The domain to serve searxng on.";
      type = types.str;
      default = "search.stahl.sh";
    };

    nginx = {
      enable = mkEnabledOption "Enable nginx for this service.";
    };

    redlib = {
      enable = mkEnabledOption "Whether or not to enable redlib.";

      domain = mkOption {
        description = "The domain to serve reddit on.";
        type = types.str;
        default = "reddit.stahl.sh";
      };
    };

    aiAnswers = {
      enable = mkBoolOpt false "Enable the AI Answers plugin PoC.";
      provider = mkOption {
        description = "LLM provider used by the AI Answers plugin.";
        type = enum [
          "openrouter"
          "openai"
          "ollama"
          "localai"
          "lmstudio"
          "gemini"
          "azure"
          "huggingface"
        ];
        default = "ollama";
      };
      model = mkOption {
        description = "Optional model identifier passed as LLM_MODEL.";
        type = nullOr str;
        default = null;
      };
      url = mkOption {
        description = "Optional provider endpoint passed as LLM_URL.";
        type = nullOr str;
        default = null;
      };
    };
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      system.sops = enabled;
      services.acme.enable = mkIf cfg.nginx.enable true;
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
      80
      443
    ];

    services = {
      searx = {
        enable = true;
        package = if cfg.aiAnswers.enable then searxPackage else pkgs.searxng;
        environmentFile = config.sops.secrets.searxng.path;
        settings = {
          server = {
            port = "1340";
            bind_address = "127.0.0.1";
            use_default_settings = true;
            secret_key = "@secret_key@";
          };
          search = {
            safe_search = 0;
            autocomplete = "google";
            formats = [
              "html"
              "json"
            ];
          };
          plugins =
            optionalAttrs cfg.redlib.enable {
              "searx.plugins.hostnames.SXNGPlugin".active = true;
            }
            // optionalAttrs cfg.aiAnswers.enable {
              "searx.plugins.ai_answers.SXNGPlugin".active = true;
            };
          hostnames.replace = mkIf cfg.redlib.enable {
            "(.*\.)?reddit\.com$" = cfg.redlib.domain;
            "(.*\.)?redd\.it$" = cfg.redlib.domain;
          };
        };
      };

      redlib = mkIf cfg.redlib.enable {
        package = pkgs.redlib;
        enable = true;
        address = "127.0.0.1";
        port = 1341;
      };

      nginx = mkIf cfg.nginx.enable {
        enable = true;

        virtualHosts = {
          "${cfg.domain}" = mkNginxProxyHost {
            proxyPass = "http://127.0.0.1:1340";
          };
          "${cfg.redlib.domain}" = mkIf cfg.redlib.enable (mkNginxProxyHost {
            proxyPass = "http://127.0.0.1:1341";
          });
        };
      };
    };

    systemd.services = mkIf cfg.aiAnswers.enable {
      searx.environment = aiAnswersEnvironment;
      searx-init.environment = aiAnswersEnvironment;
    };

    sops.secrets.searxng = mkSopsDotenvSecret sopsCfg.secretsDir "blarm-searxng.env";

  };

}
