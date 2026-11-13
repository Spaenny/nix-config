{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.monitoring;

  inherit (lib) mkIf;

  # Blackbox exporter running locally on this host.
  # Ports 9100/9115 are already taken by node exporter / OpenCloud notifications.
  blackboxExporter = "127.0.0.1:9116";

  blackboxConfig = pkgs.writeText "blackbox-exporter.yaml" ''
    modules:
      icmp4:
        prober: icmp
        timeout: 5s
        icmp:
          preferred_ip_protocol: ip4
      icmp6:
        prober: icmp
        timeout: 5s
        icmp:
          preferred_ip_protocol: ip6
      # Authoritative answer from the local zone, independent of the internet uplink.
      dns_local:
        prober: dns
        timeout: 5s
        dns:
          query_name: monapona.de
          query_type: SOA
          valid_rcodes: [NOERROR]
          validate_answer_rrs:
            fail_if_not_matches_regexp: [".*\\sSOA\\s.*"]
      # Recursive resolution through the upstream resolvers.
      dns_recursive:
        prober: dns
        timeout: 5s
        dns:
          query_name: example.com
          query_type: A
          valid_rcodes: [NOERROR]
          validate_answer_rrs:
            fail_if_not_matches_regexp: [".*\\sA\\s.*"]
      https_2xx:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          ip_protocol_fallback: true
          follow_redirects: true
  '';

  # Technitium resolvers dns-1 and dns-2.
  dnsResolvers = [
    "192.168.5.100"
    "192.168.5.200"
    "[fdf3:567b:734c:5::100]:53"
    "[fdf3:567b:734c:5::200]:53"
  ];

  ## Blackbox probe job: rewrites each target into the exporter's /probe endpoint.
  mkProbeJob = job_name: module: targets: {
    inherit job_name;
    metrics_path = "/probe";
    params.module = [ module ];
    static_configs = [ { inherit targets; } ];
    relabel_configs = [
      {
        source_labels = [ "__address__" ];
        target_label = "__param_target";
      }
      {
        source_labels = [ "__param_target" ];
        target_label = "instance";
      }
      {
        target_label = "__address__";
        replacement = blackboxExporter;
      }
    ];
  };
in
{
  config = mkIf cfg.enable {
    services.prometheus.exporters.blackbox = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9116;
      configFile = blackboxConfig;
    };

    # The module grants CAP_NET_RAW as ambient capability but empties the bounding set,
    # so ICMP probes fail with "socket: operation not permitted".
    systemd.services.prometheus-blackbox-exporter.serviceConfig.CapabilityBoundingSet = lib.mkForce [
      "CAP_NET_RAW"
    ];

    services.prometheus.scrapeConfigs = [
      # Blackbox exporter (local)
      {
        job_name = "blackbox-exporter";
        static_configs = [ { targets = [ blackboxExporter ]; } ];
      }

      # Blackbox probes: the VyOS router as blarm's gateway
      (mkProbeJob "vyos-icmp4" "icmp4" [ "192.168.10.1" ])
      (mkProbeJob "vyos-icmp6" "icmp6" [ "fdf3:567b:734c:10::1" ])
      (mkProbeJob "dns-local" "dns_local" dnsResolvers)
      (mkProbeJob "dns-recursive" "dns_recursive" dnsResolvers)
      (mkProbeJob "https_2xx" "https_2xx" [
        "https://jelly.monapona.de"
        "https://im.monapona.de"
        "https://search.stahl.sh"
        "https://ente.stahl.sh"
        "https://boehm.sh"
        "https://matrix.boehm.sh"
        "https://serverlist.tf"
        "https://u0k.de"
        "https://git.stahl.sh"
        "https://id.stahl.sh"
        "https://git.snrd.eu"
      ])
    ];
  };
}
