{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.acme;
in
{
  options.${namespace}.services.acme = {
    enable = mkBoolOpt false "ACME";
  };

  config = mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = "admin+acme@stahl.sh";
      certs."stahl.sh" = {
        domain = "stahl.sh";
        extraDomainNames = [ "*.stahl.sh" ];
        dnsProvider = "infomaniak";
        dnsPropagationCheck = true;
        environmentFile = "/run/secrets/acme";
      };
    };

    users.users.nginx.extraGroups = [ "acme" ];

    sops.secrets.acme = {
      format = "dotenv";
      sopsFile = ../../../../secrets/blarm-acme.env;
    };
  };

}
