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
  cfg = config.${namespace}.services.kanidm;
  sopsCfg = config.${namespace}.system.sops;
in
{
  imports = [
    ./home-assistant.nix
    ./immich.nix
    ./proxmox.nix
  ];

  options.${namespace}.services.kanidm = {
    enable = mkEnableOption "Kanidm identity provider";

    package = mkOption {
      description = "The Kanidm package to use.";
      type = types.package;
      default = pkgs.kanidm_1_11.withSecretProvisioning;
    };

    domain = mkOption {
      description = "The public domain to serve Kanidm on.";
      type = types.str;
      default = "id.stahl.sh";
    };

    managedDomain = mkOption {
      description = "The identity domain managed by Kanidm.";
      type = types.str;
      default = "stahl.sh";
    };

    bindAddress = mkOption {
      description = "Local address and port Kanidm listens on.";
      type = types.str;
      default = "127.0.0.1:8443";
    };

    acmeHost = mkOption {
      description = "ACME certificate name used for Kanidm TLS.";
      type = types.str;
      default = "stahl.sh";
    };

    adminUser.name = mkOption {
      description = "Kanidm administrator account name.";
      type = types.str;
      default = "philipp";
    };

    secretsFile = mkOption {
      description = "SOPS file containing Kanidm provisioning secrets.";
      type = types.path;
      default = sopsCfg.secretsDir + "/blarm-kanidm.yaml";
    };

    backup = {
      versions = mkOption {
        description = "Number of online Kanidm backups to keep.";
        type = types.ints.unsigned;
        default = 7;
      };

      schedule = mkOption {
        description = "Cron schedule for Kanidm online backups.";
        type = types.str;
        default = "30 22 * * *";
      };
    };

    nginx = {
      enable = mkEnabledOption "Enable nginx reverse proxy for Kanidm.";
    };
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      system.sops = enabled;
      services.acme.enable = true;
    };

    sops.secrets = {
      "kanidm/idm-admin-password" = {
        format = "yaml";
        key = "kanidm/idm-admin-password";
        sopsFile = cfg.secretsFile;
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      "kanidm/admin-user/display-name" = {
        format = "yaml";
        key = "kanidm/admin-user/display-name";
        sopsFile = cfg.secretsFile;
      };
      "kanidm/admin-user/legal-name" = {
        format = "yaml";
        key = "kanidm/admin-user/legal-name";
        sopsFile = cfg.secretsFile;
      };
      "kanidm/admin-user/mail-address" = {
        format = "yaml";
        key = "kanidm/admin-user/mail-address";
        sopsFile = cfg.secretsFile;
      };
    };

    sops.templates."kanidm-provision-extra.json" = {
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
      restartUnits = [ "kanidm.service" ];
      content = ''
        {
          "persons": {
            "${cfg.adminUser.name}": {
              "displayName": "${config.sops.placeholder."kanidm/admin-user/display-name"}",
              "legalName": "${config.sops.placeholder."kanidm/admin-user/legal-name"}",
              "mailAddresses": [
                "${config.sops.placeholder."kanidm/admin-user/mail-address"}"
              ]
            }
          }
        }
      '';
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.nginx.enable [
      80
      443
    ];

    services.kanidm = {
      package = cfg.package;
      client.settings.uri = "https://${cfg.domain}";
      provision = {
        enable = true;
        instanceUrl = "https://localhost:8443";
        idmAdminPasswordFile = config.sops.secrets."kanidm/idm-admin-password".path;
        extraJsonFile = config.sops.templates."kanidm-provision-extra.json".path;
        groups.idm_admins = {
          members = [ cfg.adminUser.name ];
          overwriteMembers = false;
        };
        persons.${cfg.adminUser.name} = {
          displayName = cfg.adminUser.name;
          groups = [ "idm_admins" ];
        };
      };
      server = {
        enable = true;
        settings = {
          bindaddress = cfg.bindAddress;
          origin = "https://${cfg.domain}";
          domain = cfg.managedDomain;
          tls_chain = "/var/lib/acme/${cfg.acmeHost}/fullchain.pem";
          tls_key = "/var/lib/acme/${cfg.acmeHost}/key.pem";
          online_backup = {
            inherit (cfg.backup) schedule versions;
            path = "/var/lib/kanidm/backups";
          };
        };
      };
    };

    users.users.kanidm.extraGroups = [ "acme" ];

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;
      virtualHosts."${cfg.domain}" = mkNginxProxyHost {
        proxyPass = "https://${cfg.bindAddress}";
        location = {
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_ssl_name ${cfg.domain};
            proxy_ssl_server_name on;
            proxy_ssl_verify off;
          '';
        };
      };
    };
  };
}
