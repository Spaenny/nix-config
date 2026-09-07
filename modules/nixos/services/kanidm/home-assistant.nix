{
  config,
  lib,
  namespace,
  ...
}:
with lib;
let
  cfg = config.${namespace}.services.kanidm;
in
{
  config = mkIf cfg.enable {
    sops.secrets."kanidm/oauth2/home-assistant/basic-secret" = {
      format = "yaml";
      key = "kanidm/oauth2/home-assistant/basic-secret";
      sopsFile = cfg.secretsFile;
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };

    services.kanidm.provision = {
      groups.home_assistant_users = {
        members = [ cfg.adminUser.name ];
        overwriteMembers = false;
      };

      systems.oauth2.home_assistant = {
        displayName = "Home Assistant";
        originUrl = "https://ha.monapona.de/auth/openid/callback";
        originLanding = "https://ha.monapona.de/";
        imageFile = ./assets/home-assistant.svg;
        basicSecretFile = config.sops.secrets."kanidm/oauth2/home-assistant/basic-secret".path;
        enableLegacyCrypto = true;
        preferShortUsername = true;
        scopeMaps.home_assistant_users = [
          "openid"
          "profile"
          "email"
        ];
      };
    };
  };
}
