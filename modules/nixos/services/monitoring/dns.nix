{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.monitoring;
  inherit (lib) concatStringsSep mapAttrsToList mkIf;

  # Zones served by the PowerDNS hidden primary on cancer.
  zones = [
    "boehm.sh"
    "monapona.de"
    "serverlist.tf"
    "stahl.sh"
    "u0k.de"
  ];

  # Public authoritative servers of all zones above, queried directly
  # (the local resolvers do split horizon for some of the zones).
  nameservers = {
    ns1 = "89.58.2.70";
    ns2 = "51.83.90.178";
    ns3 = "51.89.103.206";
  };

  # node exporter reads *.prom files from here (textfile collector).
  textfileDir = "/var/lib/prometheus-node-exporter-textfiles";

  dnsZoneCheck = pkgs.writeShellApplication {
    name = "dns-zone-check";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      dnsutils
      gawk
      jq
    ];
    text = ''
      zones=(${concatStringsSep " " zones})
      nameservers=(${concatStringsSep " " (mapAttrsToList (name: ip: "${name}=${ip}") nameservers)})
      out="${textfileDir}/dns-zones.prom"
      tmp=$(mktemp "${textfileDir}/.dns-zones.prom.XXXXXX")
      trap 'rm -f "$tmp"' EXIT

      q() { dig +norec +time=3 +tries=2 "$@" 2>/dev/null || true; }
      doh() { curl -fsS --max-time 10 "https://dns.google/resolve?name=$1&type=$2" 2>/dev/null || true; }

      {
        echo "# HELP dns_zone_query_success Whether the nameserver answered the SOA query for the zone."
        echo "# TYPE dns_zone_query_success gauge"
        echo "# HELP dns_zone_soa_serial SOA serial served by the nameserver."
        echo "# TYPE dns_zone_soa_serial gauge"
        echo "# HELP dns_zone_rrsig_expiry_timestamp_seconds Expiration of the RRSIG over the given RR type."
        echo "# TYPE dns_zone_rrsig_expiry_timestamp_seconds gauge"
        echo "# HELP dns_zone_ds_present Whether the parent zone publishes a DS record."
        echo "# TYPE dns_zone_ds_present gauge"
        echo "# HELP dns_zone_dnssec_validated Whether a validating public resolver answers SOA with the AD flag."
        echo "# TYPE dns_zone_dnssec_validated gauge"
        echo "# HELP dns_zone_check_last_run_timestamp_seconds Time of the last completed check."
        echo "# TYPE dns_zone_check_last_run_timestamp_seconds gauge"

        for zone in "''${zones[@]}"; do
          for entry in "''${nameservers[@]}"; do
            ns=''${entry%%=*}
            ip=''${entry#*=}
            labels="zone=\"$zone\",nameserver=\"$ns\""

            serial=$(q +short "@$ip" SOA "$zone" | awk 'NR==1 {print $3}')
            if [[ $serial =~ ^[0-9]+$ ]]; then
              echo "dns_zone_query_success{$labels} 1"
              echo "dns_zone_soa_serial{$labels} $serial"
            else
              echo "dns_zone_query_success{$labels} 0"
              continue
            fi

            for type in SOA DNSKEY; do
              exp=$(q +dnssec +noall +answer "@$ip" "$type" "$zone" \
                | awk -v t="$type" '$4 == "RRSIG" && $5 == t {print $9; exit}')
              if [[ $exp =~ ^[0-9]{14}$ ]]; then
                ts=$(date -u -d "''${exp:0:4}-''${exp:4:2}-''${exp:6:2} ''${exp:8:2}:''${exp:10:2}:''${exp:12:2}" +%s)
                echo "dns_zone_rrsig_expiry_timestamp_seconds{$labels,type=\"$type\"} $ts"
              fi
            done
          done

          ds=$(doh "$zone" DS)
          if [[ -n $ds ]]; then
            echo "dns_zone_ds_present{zone=\"$zone\"} $(jq '[.Answer[]? | select(.type == 43)] | if length > 0 then 1 else 0 end' <<<"$ds")"
          fi
          soa=$(doh "$zone" SOA)
          if [[ -n $soa ]]; then
            echo "dns_zone_dnssec_validated{zone=\"$zone\"} $(jq 'if .Status == 0 and .AD == true then 1 else 0 end' <<<"$soa")"
          fi
        done

        echo "dns_zone_check_last_run_timestamp_seconds $(date +%s)"
      } >"$tmp"

      chmod 0644 "$tmp"
      mv "$tmp" "$out"
      trap - EXIT
    '';
  };

  # Grafana-managed alert rule: Prometheus instant query A, threshold C on it.
  mkRule =
    {
      uid,
      title,
      expr,
      op,
      threshold,
      for,
      summary,
      description,
      noDataState ? "OK",
    }:
    {
      inherit
        uid
        title
        for
        noDataState
        ;
      condition = "C";
      execErrState = "Error";
      labels.severity = "critical";
      annotations = { inherit summary description; };
      # Route straight to the contact point (Discord + ntfy) instead of the policy tree.
      notification_settings.receiver = "all";
      data = [
        {
          refId = "A";
          datasourceUid = "prometheus";
          relativeTimeRange = {
            from = 600;
            to = 0;
          };
          model = {
            refId = "A";
            inherit expr;
            instant = true;
          };
        }
        {
          refId = "C";
          datasourceUid = "__expr__";
          relativeTimeRange = {
            from = 0;
            to = 0;
          };
          model = {
            refId = "C";
            type = "threshold";
            expression = "A";
            conditions = [
              {
                evaluator = {
                  type = op;
                  params = [ threshold ];
                };
              }
            ];
          };
        }
      ];
    };
in
{
  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d ${textfileDir} 0755 root root -" ];

    services.prometheus.exporters.node.extraFlags = [
      "--collector.textfile.directory=${textfileDir}"
    ];

    systemd.services.dns-zone-check = {
      description = "Check serials and DNSSEC signatures of the authoritative DNS zones";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe dnsZoneCheck;
        ProtectSystem = "strict";
        ReadWritePaths = [ textfileDir ];
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    systemd.timers.dns-zone-check = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = "15m";
      };
    };

    services.grafana.provision.alerting.rules.settings = {
      apiVersion = 1;
      groups = [
        {
          orgId = 1;
          name = "dns";
          folder = "DNS";
          interval = "5m";
          rules = [
            # Signatures normally have at least 7 days left: PowerDNS re-signs weekly.
            (mkRule {
              uid = "dns-rrsig-expiry";
              title = "DNS: RRSIG expires soon";
              expr = "min by (zone, nameserver) (dns_zone_rrsig_expiry_timestamp_seconds) - time()";
              op = "lt";
              threshold = 4 * 86400;
              for = "15m";
              summary = "RRSIG of {{ $labels.zone }} on {{ $labels.nameserver }} expires in {{ humanizeDuration $values.A.Value }}.";
              description = "The secondary did not pick up the weekly re-signing. On cancer: check the SOA-EDIT metadata of the zone, then run pdns_control notify {{ $labels.zone }}.";
            })
            # Secondaries pick up new serials after the SOA refresh (up to 8 h for some zones).
            (mkRule {
              uid = "dns-serial-mismatch";
              title = "DNS: nameservers serve different serials";
              expr = "max by (zone) (dns_zone_soa_serial) - min by (zone) (dns_zone_soa_serial)";
              op = "gt";
              threshold = 0;
              for = "12h";
              summary = "The nameservers of {{ $labels.zone }} have served different SOA serials for 12 hours.";
              description = "Zone transfers from cancer fail for at least one secondary. Check the AXFR-out entries in the pdns journal on cancer.";
            })
            (mkRule {
              uid = "dns-query-failed";
              title = "DNS: nameserver does not answer";
              expr = "dns_zone_query_success";
              op = "lt";
              threshold = 1;
              for = "30m";
              summary = "{{ $labels.nameserver }} does not answer SOA queries for {{ $labels.zone }}.";
              description = "The nameserver is down, unreachable from blarm, or no longer serves the zone.";
            })
            (mkRule {
              uid = "dns-validation-failed";
              title = "DNS: DNSSEC validation fails";
              expr = "(dns_zone_ds_present == 1) * on (zone) (1 - dns_zone_dnssec_validated)";
              op = "gt";
              threshold = 0;
              for = "30m";
              summary = "{{ $labels.zone }} has a DS record, but a validating resolver does not validate it.";
              description = "Resolvers return SERVFAIL for the zone: mail (DMARC) and websites fail. Check https://dnsviz.net/d/{{ $labels.zone }}/dnssec/";
            })
            (mkRule {
              uid = "dns-check-stale";
              title = "DNS: zone check is not running";
              expr = "time() - max(dns_zone_check_last_run_timestamp_seconds)";
              op = "gt";
              threshold = 3600;
              for = "15m";
              noDataState = "Alerting";
              summary = "dns-zone-check on blarm has not completed for over an hour.";
              description = "The DNS alerts above are blind until it runs again. Check journalctl -u dns-zone-check on blarm.";
            })
          ];
        }
      ];
    };
  };
}
