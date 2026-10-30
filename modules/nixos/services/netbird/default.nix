{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.netbird;
  sopsCfg = config.${namespace}.system.sops;
in
{
  options.${namespace}.services.netbird = {
    enable = mkEnableOption "NetBird client";

    managementUrl = mkOpt types.str "https://netbird.u0k.de" "URL of the NetBird management server.";

    setupKeySecret =
      mkOpt types.str "bodenheizung-netbird.key"
        "Name of the sops secret (binary format) holding the NetBird setup key.";
  };

  config = mkIf cfg.enable {
    ${namespace}.system.sops = enabled;

    assertions = [
      {
        assertion = cfg.setupKeySecret != "";
        message = "${namespace}.services.netbird.setupKeySecret must name a sops secret for automated login.";
      }
    ];

    sops.secrets = {
      ${cfg.setupKeySecret} = mkSopsSecret sopsCfg.secretsDir cfg.setupKeySecret {
        format = "binary";
      };
    };

    services.netbird = {
      enable = true;

      clients.default.login = {
        enable = true;
        setupKeyFile = config.sops.secrets.${cfg.setupKeySecret}.path;
      };
    };

    # The netbird CLI reads flags from NB_* environment variables (see
    # client/cmd/root.go), so this pins the self-hosted management server for
    # the automated `netbird up` login.
    #
    # The upstream login script only reacts to `NeedsLogin`/`Connected`; once
    # the daemon is in `LoginFailed` it spins until the start timeout and never
    # retries. Handle that state explicitly and let systemd retry failed
    # logins, so a transient outage at boot self-heals.
    systemd.services.netbird-login = {
      environment.NB_MANAGEMENT_URL = cfg.managementUrl;

      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "15s";
      };

      script = mkForce ''
        set -x

        status() {
          ${getExe config.services.netbird.clients.default.wrapper} status 2>&1 || :
        }

        until status | grep --quiet ': Connected\|NeedsLogin\|LoginFailed'; do
          sleep 1
        done

        if ! status | grep --quiet ': Connected'; then
          # setup key is in $NB_SETUP_KEY_FILE and is automatically picked up
          # by the CLI; NB_MANAGEMENT_URL pins the management server.
          ${getExe config.services.netbird.clients.default.wrapper} up
        fi
      '';
    };
  };
}
