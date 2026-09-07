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
    sops.secrets."kanidm/oauth2/immich/basic-secret" = {
      format = "yaml";
      key = "kanidm/oauth2/immich/basic-secret";
      sopsFile = cfg.secretsFile;
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };

    services.kanidm.provision = {
      groups.immich_users = {
        members = [ cfg.adminUser.name ];
        overwriteMembers = false;
      };

      systems.oauth2.immich = {
        displayName = "Immich";
        originUrl = [
          "https://im.monapona.de/auth/login"
          "app.immich:/oauth-callback"
        ];
        originLanding = "https://im.monapona.de/";
        imageFile = ./assets/immich.svg;
        basicSecretFile = config.sops.secrets."kanidm/oauth2/immich/basic-secret".path;
        enableLegacyCrypto = true;
        preferShortUsername = true;
        scopeMaps.immich_users = [
          "openid"
          "profile"
          "email"
        ];
      };
    };
  };
}
