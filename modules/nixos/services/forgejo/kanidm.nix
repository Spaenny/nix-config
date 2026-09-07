{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
let
  cfg = config.${namespace}.services.forgejo;
  kanidmCfg = config.${namespace}.services.kanidm;
  secret = config.sops.secrets."kanidm/oauth2/forgejo/basic-secret";
  forgejo = "${cfg.package}/bin/forgejo";
  forgejoArgs = [
    "--config"
    "/var/lib/forgejo/custom/conf/app.ini"
    "--work-path"
    "/var/lib/forgejo"
    "--custom-path"
    "/var/lib/forgejo/custom"
  ];
  forgejoArgsString = concatStringsSep " " (map escapeShellArg forgejoArgs);
in
{
  config = mkIf (cfg.enable && kanidmCfg.enable) {
    sops.secrets."kanidm/oauth2/forgejo/basic-secret" = {
      format = "yaml";
      key = "kanidm/oauth2/forgejo/basic-secret";
      sopsFile = kanidmCfg.secretsFile;
      owner = "kanidm";
      group = cfg.user;
      mode = "0440";
    };

    services.kanidm.provision = {
      groups.forgejo_users = {
        members = [ kanidmCfg.adminUser.name ];
        overwriteMembers = false;
      };

      systems.oauth2.forgejo = {
        displayName = "Forgejo";
        originUrl = "https://${cfg.domain}/user/oauth2/kanidm/callback";
        originLanding = "https://${cfg.domain}/";
        imageFile = ./assets/forgejo.svg;
        basicSecretFile = secret.path;
        enableLegacyCrypto = true;
        allowInsecureClientDisablePkce = true;
        preferShortUsername = true;
        scopeMaps.forgejo_users = [
          "openid"
          "profile"
          "email"
        ];
      };
    };

    systemd.services.forgejo-kanidm-auth-source = {
      description = "Forgejo Kanidm OIDC auth source provisioning";
      wantedBy = [ "multi-user.target" ];
      after = [
        "forgejo.service"
        "kanidm.service"
      ];
      requires = [ "forgejo.service" ];
      partOf = [ "forgejo.service" ];

      path = [
        pkgs.gawk
        pkgs.gnugrep
      ];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.user;
      };

      script = ''
        set -euo pipefail

        secret=$(cat ${escapeShellArg secret.path})
        common_args=(
          --name kanidm
          --provider openidConnect
          --key forgejo
          --secret "$secret"
          --auto-discover-url https://${kanidmCfg.domain}/oauth2/openid/forgejo/.well-known/openid-configuration
          --icon-url https://${cfg.domain}/assets/img/logo.svg
          --scopes openid
          --scopes profile
          --scopes email
          --allow-username-change
        )

        auth_id=$(${forgejo} admin auth list ${forgejoArgsString} | awk -F '\t' '$2 == "kanidm" { print $1; exit }')

        if [ -n "$auth_id" ]; then
          ${forgejo} admin auth update-oauth ${forgejoArgsString} --id "$auth_id" "''${common_args[@]}"
        else
          ${forgejo} admin auth add-oauth ${forgejoArgsString} "''${common_args[@]}"
        fi
      '';
    };
  };
}
