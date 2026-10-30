{
  config,
  inputs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.apps.hermes-agent;
  sopsEnv = "/run/secrets/${cfg.service.secretName}";
in
{
  # The upstream module owns `programs.hermes-agent` and `services.hermes-agent`.
  # Everything below only maps this repository's option shape onto it.
  imports = [ inputs.hermes-agent.homeManagerModules.default ];

  options.${namespace}.apps.hermes-agent = with types; {
    enable = mkBoolOpt false "Whether or not to install the hermes-agent CLI and its desktop application.";

    extraPackages =
      mkOpt (listOf package) [ ]
        "Tools the agent may run. They are added to the PATH of the CLI and of the service units.";

    service = {
      enable = mkBoolOpt false ''
        Whether to manage ~/.hermes declaratively and run the agent as a
        systemd user service. While this is enabled Nix owns the
        configuration: `hermes config set` refuses to write and config.yaml is
        merged with the settings below on every activation. It also pins
        terminal.cwd to the home directory.
      '';

      gateway = mkBoolOpt false "Whether to run the messaging gateway (Telegram, Discord, Slack, ...) as a user service.";

      secretName = mkOpt str "hermes-env" ''
        Name of the sops secret (dotenv) with the API keys, as declared by
        ${namespace}.services.hermes-agent. Its decrypted file is read from
        /run/secrets/<name> and merged into ~/.hermes/.env.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      programs.hermes-agent = {
        enable = true;
        desktop.enable = true;
      };

      services.hermes-agent.extraPackages = cfg.extraPackages;

      assertions = [
        {
          assertion = !cfg.service.gateway || cfg.service.enable;
          message = "The hermes-agent gateway needs ${namespace}.apps.hermes-agent.service.enable = true.";
        }
      ];
    })

    (mkIf (cfg.enable && cfg.service.enable) {
      services.hermes-agent = {
        enable = true;
        gateway.enable = cfg.service.gateway;
        environmentFiles = [ sopsEnv ];

        # Cortecs is the only provider. The key stays in the sops secret: the
        # ref below resolves against ~/.hermes/.env at load time, and the entry
        # repeats the variable name for the custom-provider lookup. Models are
        # left to autodiscovery.
        settings = {
          model = {
            default = "deepseek-v4.1-flash-1017";
            provider = "custom";
            base_url = "https://api.cortecs.ai/v1";
            api_mode = "chat_completions";
            api_key = "\${env:CORTECS_API_KEY}";
          };

          custom_providers = [
            {
              name = "CORTECS";
              base_url = "https://api.cortecs.ai/v1";
              key_env = "CORTECS_API_KEY";
              models_discovered = true;
            }
          ];
        };
      };
    })
  ];
}
