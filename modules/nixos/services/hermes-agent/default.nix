{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.hermes-agent;
  sopsCfg = config.${namespace}.system.sops;
in
{
  options.${namespace}.services.hermes-agent = with types; {
    enable = mkBoolOpt false "Whether to declare the sops secret with the hermes-agent API keys and keep the user manager alive across logouts.";

    user =
      mkOpt str "philipp"
        "User that runs the hermes-agent user services. It may read the decrypted environment file.";

    secretName =
      mkOpt str "hermes-env"
        "Name of the sops secret. The decrypted dotenv file appears at /run/secrets/<name> and must match the secretName of the home module.";

    secretFile =
      mkOpt str "bodenheizung-hermes.env"
        "Encrypted sops file below the secrets directory that holds the API keys as dotenv.";
  };

  config = mkIf cfg.enable {
    ${namespace}.system.sops = enabled;

    # The home module reads this path as an environment file, so the owner must
    # be the user that runs the gateway. 0400 keeps the other accounts out.
    sops.secrets.${cfg.secretName} = mkSopsDotenvSecret sopsCfg.secretsDir cfg.secretFile // {
      owner = cfg.user;
      mode = "0400";
    };

    # The gateway is a systemd *user* unit. Without linger the user manager
    # stops at logout and takes every unit with it.
    users.users.${cfg.user}.linger = true;
  };
}
