{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
let
  cfg = config.${namespace}.services.monitoring;
  kanidmCfg = config.${namespace}.services.kanidm;
  secret = config.sops.secrets."kanidm/oauth2/grafana/basic-secret";
in
{
  config = mkIf (cfg.enable && kanidmCfg.enable) {
    sops.secrets."kanidm/oauth2/grafana/basic-secret" = {
      format = "yaml";
      key = "kanidm/oauth2/grafana/basic-secret";
      sopsFile = kanidmCfg.secretsFile;
      owner = "kanidm";
      group = "grafana";
      mode = "0440";
    };

    services.kanidm.provision = {
      groups.grafana_admins = {
        members = [ kanidmCfg.adminUser.name ];
        overwriteMembers = false;
      };

      groups.grafana_users = {
        members = [ kanidmCfg.adminUser.name ];
        overwriteMembers = false;
      };

      systems.oauth2.grafana = {
        displayName = "Grafana";
        originUrl = "https://${cfg.statsDomain}/login/generic_oauth";
        originLanding = "https://${cfg.statsDomain}/login";
        basicSecretFile = secret.path;
        preferShortUsername = true;
        scopeMaps.grafana_users = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        claimMaps.grafana_role = {
          joinType = "array";
          valuesByGroup.grafana_admins = [ "GrafanaAdmin" ];
        };
      };
    };

    services.grafana = {
      settings = {
        server.domain = cfg.statsDomain;
        server.root_url = "https://${cfg.statsDomain}/";
        "auth.generic_oauth" = {
          enabled = true;
          name = "Kanidm";
          icon = "signin";
          client_id = "grafana";
          client_secret = "$__file{${secret.path}}";
          scopes = "openid profile email groups";
          auth_url = "https://${kanidmCfg.domain}/ui/oauth2";
          token_url = "https://${kanidmCfg.domain}/oauth2/token";
          api_url = "https://${kanidmCfg.domain}/oauth2/openid/grafana/userinfo";
          login_attribute_path = "preferred_username";
          name_attribute_path = "name";
          email_attribute_path = "email";
          groups_attribute_path = "grafana_role";
          role_attribute_path = "contains(grafana_role[*], 'GrafanaAdmin') && 'GrafanaAdmin' || 'Viewer'";
          allow_assign_grafana_admin = true;
          allow_sign_up = true;
          auto_login = false;
          use_pkce = true;
          use_refresh_token = true;
        };
      };
    };

    systemd.services.grafana = {
      after = [ "kanidm.service" ];
      wants = [ "kanidm.service" ];
    };
  };
}
