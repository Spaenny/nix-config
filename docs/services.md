# Services on blarm

## Overview

All public domains go through nginx with the wildcard certificate for `stahl.sh`. A fallback host `_` answers unknown hostnames with 404, so such requests don't end up at the first application host.

| Domain | Service | Local port | Data | Database |
| --- | --- | --- | --- | --- |
| `git.stahl.sh` | Forgejo | 3001 | `/var/lib/forgejo` | PostgreSQL |
| `id.stahl.sh` | Kanidm | 8443 (TLS) | `/var/lib/kanidm` | internal |
| `stats.stahl.sh` | Grafana | 3002 | default path | internal |
| `collector.stahl.sh` | Prometheus with basic auth | 9090 | default path | internal |
| `cloud.stahl.sh` | OpenCloud | 9200 | `/data/opencloud` | internal |
| `collabora.stahl.sh` | Collabora Online | 9980 | – | – |
| `wopiserver.stahl.sh` | OpenCloud WOPI | 9300 | – | – |
| `ente.stahl.sh` | Ente Auth, web and API under `/api/` | 6789 | `/data/ente` | PostgreSQL |
| `link.stahl.sh` | Linkwarden | 3000 | default path | upstream module default |
| `paperless.stahl.sh` | Paperless-ngx | 28981 | `/data/paperless` | SQLite |
| `search.stahl.sh` | SearXNG | 1340 | – | – |
| `reddit.stahl.sh` | Redlib | 1341 | – | – |
| `cinny.stahl.sh` | Cinny, static files | – | – | – |

### Other ports

| Port | Service | Binding |
| --- | --- | --- |
| 139, 445 (TCP), 137, 138 (UDP) | Samba | open in firewall, access limited to `192.168.1.0/24` |
| 8384 | Syncthing web UI | `192.168.10.3`, open in firewall |
| 9100 | Node Exporter | local |
| 9101 | OpenCloud web | local |
| 9116 | Blackbox Exporter | local |
| 9221 | Proxmox Exporter | local |
| 9233 | OpenCloud registry (NATS) | local |

Ports 9100 and 9115 are taken or claimed by OpenCloud. That is why OpenCloud web is on 9101 and the Blackbox Exporter on 9116.

## TLS certificate

`services.acme` requests `stahl.sh` and `*.stahl.sh` via DNS challenge through PowerDNS. The credentials are in `secrets/blarm-acme.env`. Both nginx and Kanidm are members of the `acme` group, because Kanidm uses the certificate directly for its own TLS.

## Single sign-on with Kanidm

Kanidm is the identity provider. Users, groups and OAuth2 clients are declared. The admin user is `philipp`.

| Client | Origin | Group |
| --- | --- | --- |
| Forgejo | `https://git.stahl.sh` | `forgejo_users` |
| Grafana | `https://stats.stahl.sh` | `grafana_users`, admin rights via `grafana_admins` |
| Home Assistant | `https://ha.monapona.de` | `home_assistant_users` |
| Immich | `https://im.monapona.de` | `immich_users` |
| Proxmox | `https://pve.monapona.de` | `proxmox_users` |

Home Assistant, Immich and Proxmox don't run on `blarm`. Only their client registration lives here.

Details:

- All groups set `overwriteMembers = false`, so manually added members are kept.
- The admin's name and email are stored as a secret and applied through the template `kanidm-provision-extra.json`.
- The oneshot unit `forgejo-kanidm-auth-source` creates or updates the authentication source in Forgejo.
- Grafana assigns the `GrafanaAdmin` role through the `grafana_role` claim, all other users are `Viewer`.

## Monitoring

Prometheus (15-day retention) and Grafana run locally. Prometheus is provisioned in Grafana as the default data source. From outside, Prometheus is reachable at `collector.stahl.sh` with basic auth.

| Job | Target |
| --- | --- |
| `prometheus` | itself |
| `node` | Node Exporter on `blarm`, including the systemd collector and the textfile collector (`/var/lib/prometheus-node-exporter-textfiles`) |
| `vyos-node` | Node Exporter of the VyOS router, `192.168.10.1:9100` |
| `cancer-container` | cAdvisor on `192.168.100.3:9180`, with `sample_limit` 10,000 |
| `proxmox` | Proxmox exporter for `pve.monapona.de:443` |
| `blackbox-exporter` | the Blackbox Exporter itself |
| `vyos-icmp4`, `vyos-icmp6` | ICMP probes against the VyOS router, blarm's gateway (`192.168.10.1`, `fdf3:567b:734c:10::1`) |
| `dns-local`, `dns-recursive` | DNS probes against dns-1 and dns-2 (`.100`, `.200`, IPv4 and IPv6): SOA of the local zone `monapona.de`, and `example.com` resolved recursively |
| `https_2xx` | HTTP probes against the web services, the list is in `monitoring/blackbox.nix` |

Dashboards are not declared in the repository.

### Alerting

All Grafana alert rules are provisioned from `monitoring/alerts.nix` and `monitoring/dns.nix` and cannot be edited in the UI. `monitoring/alert-rule.nix` builds each rule as a Prometheus instant query with a threshold. Every rule notifies the contact point `all` (Discord and ntfy, configured in the Grafana UI) directly, bypassing the notification policies.

| Folder | Group | Rules |
| --- | --- | --- |
| `Hosts` | `targets` | any scrape target down for 2 minutes (covers all node exporters, PowerDNS, cAdvisor, Proxmox) |
| `Hosts` | `hosts-critical` | root/data filesystem read-only, disk above 95 % |
| `Hosts` | `hosts-warning` | disk or inodes above 90 %, CPU or RAM above 90 %, load15 above 1.5 per core, IO wait above 20 %, network errors above 0.1/s, failed systemd unit, host rebooted, OOM kill, clock not synchronised, backup timer (restic, PostgreSQL dump) not fired for 36 hours |
| `Network` | `network` | router not answering ping, DNS resolver dns-1/dns-2 failing |
| `Proxmox` | `proxmox` | node down, guest with "start at boot" stopped, storage above 90 % |
| `Websites` | `websites` | `https_2xx` probe failing, slower than 2 s, certificate expiring within 14 days |
| `DNS` | `powerdns` | no queries on ns1, packet errors, PowerDNS restarted |
| `DNS` | `dns` | see below |

`deleteRules` in `alerts.nix` lists the UIDs of rules that were created in the UI before. On blarm, an LXC container, `/proc/vmstat` and the clock are those of the Proxmox node, so the OOM and time alerts for blarm describe all of n5.

The Blackbox Exporter needs `CAP_NET_RAW` in its bounding set for ICMP; `blackbox.nix` overrides the empty `CapabilityBoundingSet` of the NixOS module.

### Authoritative DNS

The timer `dns-zone-check` runs every 15 minutes and queries `ns1`–`ns3` directly for each zone of the PowerDNS hidden primary on `cancer`. It writes `dns_zone_*` metrics (SOA serial, RRSIG expiry, DS present, validated by `dns.google`) for the textfile collector. Zones and nameserver addresses are in `monitoring/dns.nix`.

The same module provisions the alert rules of the group `dns` in the folder `DNS`:

| Rule | Fires when |
| --- | --- |
| `dns-rrsig-expiry` | an RRSIG on a nameserver expires in less than 4 days (normally at least 7, PowerDNS re-signs weekly) |
| `dns-serial-mismatch` | the nameservers of a zone serve different serials for 12 hours |
| `dns-query-failed` | a nameserver does not answer SOA for a zone for 30 minutes |
| `dns-validation-failed` | a zone with a DS record does not validate for 30 minutes |
| `dns-check-stale` | the check has not completed for over an hour |
## Backups

All jobs run at night:

| Time | Job | Destination |
| --- | --- | --- |
| 22:30 | Kanidm online backup, 7 versions | `/var/lib/kanidm/backups` |
| 23:30 | PostgreSQL dump of all databases | `/var/backup/postgresql` |
| 00:10 + up to 1 h random delay | Restic backup `borgbase` | external repository, the URL is in the secret |

Restic backs up `/home`, `/var/lib`, `/data` and the PostgreSQL dumps. Excluded are `/home/*/.cache`, `/data/lost+found`, `/var/lib/containers` and `/var/lib/docker`.

- **Retention:** 7 daily, 4 weekly, 6 monthly, 2 yearly
- **Check:** `--read-data-subset=5%`

The other hosts deliberately have no backup: the Technitium zones on `dns` and `aquarius` are easy to recreate. How to restore data is described under [Operations](operations.md#checking-and-restoring-backups).

## Notes on individual services

**Forgejo:** A oneshot unit copies the files from `codeberg-themes` to `/var/lib/forgejo/custom/public/assets` before every start. The default theme is `codeberg-dark`. SSH clones go through `stahl.sh` instead of `git.stahl.sh`.

**OpenCloud:** The service requires the mount unit `data.mount` and does not start without `/data`. The configuration under `/data/opencloud/config` is read-only for the main service. Collabora runs in `home_mode` without its own TLS behind nginx.

**Samba:** The `opencloud` share points directly to the storage path of one OpenCloud user. The path contains that user's UUID and is hard-coded in the module. The Samba user `philipp` writes there as `opencloud`.

**Ente:** The server uses PostgreSQL with peer authentication, so the database name and user must match. An assertion checks this. sops-nix renders the credentials as `ente-server-credentials.yaml`. Only Ente Auth runs, so no S3 section is needed.

**SearXNG:** The `secret_key` value in the configuration is a placeholder, the real value comes from `secrets/blarm-searxng.env`. The AI Answers plugin is copied into the package at build time and on `blarm` uses the `ollama` provider with the `gemma3:4b` model. The Ollama server runs externally on `192.168.10.201`, the address comes as `LLM_URL` from `secrets/blarm-searxng.env`. Links to Reddit are rewritten to `reddit.stahl.sh`.

**Paperless:** The OCR languages are German and English.

**Linkwarden:** By default the service listens on `0.0.0.0:3000`. The firewall only opens 80 and 443.
