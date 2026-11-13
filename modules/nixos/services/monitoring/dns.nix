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

  mkRule = import ./alert-rule.nix { inherit lib; };
  zone = "{{ $labels.zone }}";
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
              title = "DNSSEC signature expiring";
              expr = "min by (zone, nameserver) (dns_zone_rrsig_expiry_timestamp_seconds) - time()";
              op = "lt";
              threshold = 4 * 86400;
              for = "15m";
              severity = "critical";
              summary = "DNSSEC signature of ${zone} on {{ $labels.nameserver }} expires in {{ humanizeDuration $values.A.Value }}";
              description = "The secondary did not pick up the weekly re-signing. On cancer, check the SOA-EDIT metadata of the zone (pdnsutil get-meta ${zone}), then run pdns_control notify ${zone}.";
            })
            # Secondaries pick up new serials after the SOA refresh (up to 8 h for some zones).
            (mkRule {
              uid = "dns-serial-mismatch";
              title = "DNS serials differ";
              expr = "max by (zone) (dns_zone_soa_serial) - min by (zone) (dns_zone_soa_serial)";
              op = "gt";
              threshold = 0;
              for = "12h";
              summary = "The nameservers of ${zone} have served different serials for 12 hours";
              description = "At least one secondary no longer transfers the zone from cancer. Check the AXFR-out entries in the pdns journal on cancer.";
            })
            (mkRule {
              uid = "dns-query-failed";
              title = "Nameserver not answering";
              expr = "dns_zone_query_success";
              op = "lt";
              threshold = 1;
              for = "30m";
              summary = "{{ $labels.nameserver }} does not answer queries for ${zone}";
              description = "The nameserver is down, unreachable from blarm, or no longer serves the zone.";
            })
            (mkRule {
              uid = "dns-validation-failed";
              title = "DNSSEC validation failing";
              expr = "(dns_zone_ds_present == 1) * on (zone) (1 - dns_zone_dnssec_validated)";
              op = "gt";
              threshold = 0;
              for = "30m";
              severity = "critical";
              summary = "${zone} no longer validates with DNSSEC";
              description = "Validating resolvers return SERVFAIL: mail (DMARC) and websites of the domain fail. Details: https://dnsviz.net/d/${zone}/dnssec/";
            })
            (mkRule {
              uid = "dns-check-stale";
              title = "DNS check not running";
              expr = "time() - max(dns_zone_check_last_run_timestamp_seconds)";
              op = "gt";
              threshold = 3600;
              for = "15m";
              noDataState = "Alerting";
              summary = "dns-zone-check on blarm has not run for over an hour";
              description = "The DNS alerts are blind until it runs again. Check journalctl -u dns-zone-check on blarm.";
            })
          ];
        }
      ];
    };
  };
}
