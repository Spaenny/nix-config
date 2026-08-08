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
  sopsCfg = config.${namespace}.system.sops;
in
{
  options.${namespace}.services.acme = {
    enable = mkBoolOpt false "ACME";
  };

  config = mkIf cfg.enable {
    ${namespace}.system.sops = enabled;

    security.acme = {
      acceptTerms = true;
      defaults.email = "admin+acme@stahl.sh";
      certs."stahl.sh" = {
        domain = "stahl.sh";
        extraDomainNames = [ "*.stahl.sh" ];
        dnsProvider = "infomaniak";
        dnsPropagationCheck = true;
        environmentFile = config.sops.secrets.acme.path;
      };
    };

    users.users.nginx.extraGroups = [ "acme" ];

    sops.secrets.acme = mkSopsDotenvSecret sopsCfg.secretsDir "blarm-acme.env";
  };

}
