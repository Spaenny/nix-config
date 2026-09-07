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
    sops.secrets."kanidm/oauth2/proxmox/basic-secret" = {
      format = "yaml";
      key = "kanidm/oauth2/proxmox/basic-secret";
      sopsFile = cfg.secretsFile;
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };

    services.kanidm.provision = {
      groups.proxmox_users = {
        members = [ cfg.adminUser.name ];
        overwriteMembers = false;
      };

      systems.oauth2.proxmox = {
        displayName = "Proxmox";
        originUrl = [
          "https://pve.monapona.de"
        ];
        originLanding = "https://pve.monapona.de/";
        imageFile = ./assets/proxmox.svg;
        basicSecretFile = config.sops.secrets."kanidm/oauth2/proxmox/basic-secret".path;
        enableLegacyCrypto = true;
        allowInsecureClientDisablePkce = true;
        preferShortUsername = true;
        scopeMaps.proxmox_users = [
          "openid"
          "profile"
          "email"
        ];
      };
    };
  };
}
