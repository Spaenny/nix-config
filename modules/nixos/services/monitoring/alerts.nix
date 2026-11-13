{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.monitoring;
  inherit (lib) mkIf;

  mkRule = import ./alert-rule.nix { inherit lib; };

  # Real disks only: no RAM-backed, overlay or FUSE mounts (VyOS config sessions).
  fs = ''fstype!~"tmpfs|overlay|squashfs|ramfs|fuse.*"'';
  # Root and data mounts; /nix/store is read-only by design.
  fsMounts = ''${fs}, mountpoint=~"/|/data|/media"'';

  diskUsed = "100 * (1 - node_filesystem_avail_bytes{${fs}} / node_filesystem_size_bytes{${fs}})";

  pdnsQueries =
    lib.concatMapStringsSep " + "
      (proto: ''(sum(rate(pdns_auth_${proto}_queries{instance="ns1.boehm.sh"}[5m])) or vector(0))'')
      [
        "udp4"
        "udp6"
        "tcp4"
        "tcp6"
      ];

  host = "{{ $labels.instance }}";
  value = fmt: "{{ printf \"${fmt}\" $values.A.Value }}";
in
{
  config = mkIf cfg.enable {
    services.grafana.provision.alerting.rules.settings = {
      apiVersion = 1;

      groups = [
        {
          orgId = 1;
          name = "targets";
          folder = "Hosts";
          interval = "1m";
          rules = [
            # Covers every scrape job, including the ns1 node exporter and PowerDNS through WireGuard.
            (mkRule {
              uid = "scrape-target-down";
              title = "Scrape target down";
              expr = "up";
              op = "lt";
              threshold = 1;
              for = "2m";
              keepFiringFor = "5m";
              severity = "critical";
              execErrState = "Error";
              summary = "Unreachable: ${host} ({{ $labels.job }})";
              description = "Prometheus on blarm has not reached the target for 2 minutes. Check host, exporter and firewall, for ns1 also WireGuard (wg-ns1).";
            })
          ];
        }

        {
          orgId = 1;
          name = "hosts-critical";
          folder = "Hosts";
          interval = "1m";
          rules = [
            (mkRule {
              uid = "host-filesystem-readonly";
              title = "Filesystem read-only";
              expr = "node_filesystem_readonly{${fsMounts}}";
              op = "gt";
              threshold = 0;
              for = "5m";
              keepFiringFor = "5m";
              severity = "critical";
              summary = "Filesystem read-only on ${host} ({{ $labels.mountpoint }})";
              description = "The filesystem ({{ $labels.fstype }}) was remounted read-only, usually after I/O errors. Check the kernel log (dmesg) and disk health.";
            })
            (mkRule {
              uid = "host-disk-critical";
              title = "Disk space critical";
              expr = diskUsed;
              op = "gt";
              threshold = 95;
              for = "5m";
              keepFiringFor = "5m";
              severity = "critical";
              summary = "Disk space critical on ${host} ({{ $labels.mountpoint }}: ${value "%.1f"} % used)";
              description = "Less than 5 % free. Services can fail at any moment, clean up now.";
            })
          ];
        }

        {
          orgId = 1;
          name = "hosts-warning";
          folder = "Hosts";
          interval = "1m";
          rules = [
            (mkRule {
              uid = "host-disk-full";
              title = "Disk space low";
              expr = diskUsed;
              op = "gt";
              threshold = 90;
              for = "5m";
              keepFiringFor = "5m";
              summary = "Disk space low on ${host} ({{ $labels.mountpoint }}: ${value "%.1f"} % used)";
              description = "Check logs, backups, Docker images and old Nix generations.";
            })
            (mkRule {
              uid = "host-inodes-full";
              title = "Inodes low";
              # Filesystems without an inode limit (vfat, ZFS datasets) report 0 files.
              expr = "100 * (1 - node_filesystem_files_free{${fs}} / (node_filesystem_files{${fs}} > 0))";
              op = "gt";
              threshold = 90;
              for = "5m";
              keepFiringFor = "5m";
              summary = "Inodes low on ${host} ({{ $labels.mountpoint }}: ${value "%.1f"} % used)";
              description = "Many small files, often caches or mail queues. Find the largest directories with `du --inodes`.";
            })
            (mkRule {
              uid = "host-cpu-high";
              title = "High CPU usage";
              expr = ''100 - avg by (job, instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100'';
              op = "gt";
              threshold = 90;
              for = "10m";
              keepFiringFor = "5m";
              summary = "High CPU usage on ${host} (${value "%.0f"} %)";
              description = "Above 90 % for 10 minutes. Check processes with top/htop.";
            })
            (mkRule {
              uid = "host-memory-high";
              title = "High memory usage";
              expr = "100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)";
              op = "gt";
              threshold = 90;
              for = "10m";
              keepFiringFor = "5m";
              summary = "High memory usage on ${host} (${value "%.0f"} %)";
              description = "Less than 10 % of RAM available for 10 minutes. The OOM killer may stop services.";
            })
            (mkRule {
              uid = "host-load-high";
              title = "High load";
              expr = ''node_load15 / count without (cpu, mode) (node_cpu_seconds_total{mode="idle"})'';
              op = "gt";
              threshold = 1.5;
              for = "15m";
              summary = "High load on ${host} (${value "%.2f"} per CPU core)";
              description = "The 15-minute load is above 1.5 times the core count. Check CPU, IO wait and blocked processes.";
            })
            (mkRule {
              uid = "host-iowait-high";
              title = "High IO wait";
              expr = ''100 * avg by (job, instance) (rate(node_cpu_seconds_total{mode="iowait"}[5m]))'';
              op = "gt";
              threshold = 20;
              for = "10m";
              summary = "High IO wait on ${host} (${value "%.0f"} %)";
              description = "The CPU has spent over 20 % waiting for disk I/O for 10 minutes. Check disk latency, backups and databases.";
            })
            (mkRule {
              uid = "host-network-errors";
              title = "Network errors";
              # VyOS reports a few errors on wg0 all the time; only sustained error rates matter.
              expr = ''sum by (job, instance, device) (rate(node_network_receive_errs_total{device!~"lo|veth.*|docker.*|br.*"}[5m]) + rate(node_network_transmit_errs_total{device!~"lo|veth.*|docker.*|br.*"}[5m]))'';
              op = "gt";
              threshold = 0.1;
              for = "15m";
              summary = "Network errors on ${host} ({{ $labels.device }}: ${value "%.2f"} per second)";
              description = "Send or receive errors for 15 minutes. Check interface statistics (ip -s link), cabling or the provider.";
            })
            (mkRule {
              uid = "host-systemd-unit-failed";
              title = "Systemd unit failed";
              expr = ''node_systemd_unit_state{state="failed"} == 1'';
              op = "gt";
              threshold = 0;
              for = "5m";
              summary = "{{ $labels.name }} failed on ${host}";
              description = "Find the cause with systemctl status {{ $labels.name }} and journalctl -u {{ $labels.name }}.";
            })
            (mkRule {
              uid = "host-rebooted";
              title = "Host rebooted";
              expr = "time() - node_boot_time_seconds";
              op = "lt";
              threshold = 600;
              summary = "${host} rebooted";
              description = "The host has been up for less than 10 minutes. If the reboot was not planned, check journalctl -b -1.";
            })
            (mkRule {
              uid = "host-oom-kill";
              title = "OOM killer active";
              expr = "increase(node_vmstat_oom_kill[15m])";
              op = "gt";
              threshold = 0;
              summary = "OOM killer stopped processes on ${host}";
              description = "The kernel ran out of memory and killed processes. Check journalctl -k | grep -i oom. On LXC containers such as blarm the counter is that of the Proxmox node: the kill can have happened in any guest on n5.";
            })
            # Time matters for DNSSEC signatures, TLS and TOTP.
            (mkRule {
              uid = "host-time-not-synced";
              title = "Clock not synchronised";
              expr = "node_timex_sync_status";
              op = "lt";
              threshold = 1;
              for = "15m";
              summary = "Clock on ${host} is not synchronised";
              description = "NTP lost synchronisation for 15 minutes. Check timedatectl and the NTP service.";
            })
            # A failed run is reported by "Systemd unit failed"; this catches timers that stop firing.
            (mkRule {
              uid = "host-backup-stale";
              title = "Backup not running";
              expr = ''time() - node_systemd_timer_last_trigger_seconds{name=~"restic-backups-.*\\.timer|postgresqlBackup\\.timer"}'';
              op = "gt";
              threshold = 36 * 3600;
              for = "15m";
              summary = "{{ $labels.name }} on ${host} has not fired for {{ humanizeDuration $values.A.Value }}";
              description = "The nightly backup timer did not run. Check systemctl list-timers and the timer unit.";
            })
          ];
        }

        {
          orgId = 1;
          name = "network";
          folder = "Network";
          interval = "1m";
          rules = [
            (mkRule {
              uid = "router-ping-failed";
              title = "Router not answering ping";
              expr = ''probe_success{job=~"vyos-icmp.*"}'';
              op = "lt";
              threshold = 1;
              for = "2m";
              severity = "critical";
              summary = "Router ${host} does not answer ping";
              description = "blarm gets no ICMP echo reply from its gateway for 2 minutes. Alerts to Discord/ntfy may not get out either.";
            })
            (mkRule {
              uid = "dns-resolver-failed";
              title = "DNS resolver failing";
              expr = ''probe_success{job=~"dns-local|dns-recursive"}'';
              op = "lt";
              threshold = 1;
              for = "3m";
              severity = "critical";
              summary = "DNS resolver ${host} fails ({{ $labels.job }})";
              description = "dns-local: the resolver does not answer the SOA of monapona.de. dns-recursive: it cannot resolve example.com (upstream or internet). Check Technitium on dns-1/dns-2.";
            })
          ];
        }

        {
          orgId = 1;
          name = "proxmox";
          folder = "Proxmox";
          interval = "1m";
          rules = [
            (mkRule {
              uid = "pve-node-down";
              title = "Proxmox node down";
              expr = ''pve_up{id=~"node/.*"}'';
              op = "lt";
              threshold = 1;
              for = "2m";
              severity = "critical";
              summary = "Proxmox node {{ $labels.id }} is down";
              description = "The Proxmox API reports the node as offline.";
            })
            # Only guests with "start at boot" are expected to run.
            (mkRule {
              uid = "pve-guest-down";
              title = "Proxmox guest stopped";
              expr = ''(1 - pve_up{id=~"(qemu|lxc)/.*"}) * on (id) group_left () (pve_onboot_status == 1) * on (id) group_left (name) pve_guest_info'';
              op = "gt";
              threshold = 0;
              for = "5m";
              severity = "critical";
              summary = "Proxmox guest {{ $labels.name }} ({{ $labels.id }}) is not running";
              description = "The guest has \"start at boot\" enabled but is stopped. Start it in Proxmox or disable start at boot if it is retired.";
            })
            (mkRule {
              uid = "pve-storage-full";
              title = "Proxmox storage full";
              expr = ''100 * pve_disk_usage_bytes{id=~"storage/.*"} / pve_disk_size_bytes{id=~"storage/.*"}'';
              op = "gt";
              threshold = 90;
              for = "15m";
              summary = "Proxmox storage {{ $labels.id }} is ${value "%.1f"} % full";
              description = "VM disks and containers on this storage can fail to write. Clean up snapshots, backups or old images.";
            })
          ];
        }

        {
          orgId = 1;
          name = "websites";
          folder = "Websites";
          interval = "1m";
          rules = [
            (mkRule {
              uid = "website-down";
              title = "Website down";
              expr = ''probe_success{job="https_2xx"}'';
              op = "lt";
              threshold = 1;
              for = "2m";
              severity = "critical";
              summary = "Website down: ${host}";
              description = "No 2xx response over HTTPS for 2 minutes (probed from blarm).";
            })
            (mkRule {
              uid = "website-slow";
              title = "Website slow";
              expr = ''probe_duration_seconds{job="https_2xx"}'';
              op = "gt";
              threshold = 2;
              for = "5m";
              summary = "Slow response: ${host} (${value "%.1f"} s)";
              description = "The HTTPS response has taken over 2 seconds for 5 minutes.";
            })
            (mkRule {
              uid = "website-tls-expiry";
              title = "TLS certificate expiring";
              expr = ''probe_ssl_earliest_cert_expiry{job="https_2xx"} - time()'';
              op = "lt";
              threshold = 14 * 86400;
              for = "1h";
              summary = "TLS certificate of ${host} expires in {{ humanizeDuration $values.A.Value }}";
              description = "ACME normally renews 30 days before expiry. Check the renewal on the host serving the site (journalctl -u acme-*).";
            })
          ];
        }

        {
          orgId = 1;
          name = "powerdns";
          folder = "DNS";
          interval = "1m";
          rules = [
            (mkRule {
              uid = "pdns-no-queries";
              title = "PowerDNS receives no queries";
              expr = pdnsQueries;
              op = "lt";
              threshold = 0.01;
              for = "15m";
              labels.instance = "ns1.boehm.sh";
              summary = "ns1.boehm.sh receives no DNS queries";
              description = "Practically no UDP/TCP queries for 15 minutes. Check reachability of port 53, the firewall and the delegation.";
            })
            (mkRule {
              uid = "pdns-packet-errors";
              title = "PowerDNS packet errors";
              expr = ''(sum(rate(pdns_auth_corrupt_packets{instance="ns1.boehm.sh"}[5m])) or vector(0)) + (sum(rate(pdns_auth_timedout_packets{instance="ns1.boehm.sh"}[5m])) or vector(0))'';
              op = "gt";
              threshold = 0;
              for = "5m";
              labels.instance = "ns1.boehm.sh";
              summary = "PowerDNS on ns1.boehm.sh reports corrupt or timed out packets";
              description = "Corrupt or timed out packets for 5 minutes. Check the network, abusive clients and journalctl -u pdns.";
            })
            (mkRule {
              uid = "pdns-restarted";
              title = "PowerDNS restarted";
              expr = ''resets(pdns_auth_uptime{instance="ns1.boehm.sh"}[15m])'';
              op = "gt";
              threshold = 0;
              labels.instance = "ns1.boehm.sh";
              summary = "PowerDNS on ns1.boehm.sh restarted";
              description = "The uptime was reset within the last 15 minutes. If this was not planned, check journalctl -u pdns.";
            })
          ];
        }
      ];

      # Rules created in the UI before they were declared here (replaced by the rules above).
      deleteRules =
        map
          (uid: {
            orgId = 1;
            inherit uid;
          })
          [
            # Blackbox
            "efyt9zx3w2ha8f"
            "afytae8qqzzeoe"
            "cfytanzfssr28c"
            # Node Exporter / node-critical
            "bfzgkakb4nvnkb"
            "bfzglclmsbnk0a"
            "0245044e-64b4-53b2-ab85-7ad9691ef8fc"
            "78998e68-79d3-50a6-b907-2d801d16299e"
            "307d0efe-0539-5f43-b382-40eb5dcd57ec"
            # Node Exporter / node-warning
            "efzgjpxiwmygwf"
            "afzgjweznhmo0d"
            "dfzgk0gq383r4c"
            "dfzgk2qiw0qv4a"
            "ffzgkdnhyy7eof"
            "ba8a116d-a38f-5259-b22b-0c30d557ad49"
            "8b1a35c3-4d43-556c-8754-f5f6eb78374b"
            "cceb38d6-5ed6-5815-9894-27b9d5df6062"
            "2e92b4f0-28d8-56e7-9117-34eb11e575c6"
            "ffcc4e2c-607c-55d7-96d1-e15dda080acd"
            "eef9c520-6e14-5f21-8e0b-26d0b94a3e13"
            "d97fa3be-745e-5433-a49b-8d8baf7d2351"
            "08087a81-a2d6-59c1-80a2-de448954e018"
            # PowerDNS/DNS
            "d8c24db1-5df0-50d3-a305-7200a816b0d3"
            "cc3de347-c5af-5b95-ae2d-3e34dce3d68e"
            "45c1ef7c-dc5a-5cda-b4cc-04bdc35495b9"
            "d82c0e43-309c-59a0-9fd3-098aab081715"
            # Test rule of the DNS group
            "dns-test"
          ];
    };
  };
}
