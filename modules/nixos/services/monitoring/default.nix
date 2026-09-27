{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.monitoring;
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) enabled mkOpt;
in
{
  imports = [
    ./blackbox.nix
    ./grafana.nix
    ./kanidm.nix
    ./prometheus.nix
  ];

  options.${namespace}.services.monitoring = {
    enable = mkEnableOption "Grafana and Prometheus monitoring";

    instance =
      mkOpt lib.types.str config.networking.hostName
        "Instance label for scraped node metrics.";

    statsDomain = mkOpt lib.types.str "stats.stahl.sh" "Public domain of the Grafana instance.";
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      system.sops = enabled;
      services.acme = enabled;
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
