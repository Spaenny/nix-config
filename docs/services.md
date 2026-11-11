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
| `node` | Node Exporter on `blarm`, including the systemd collector |
| `vyos-node` | Node Exporter of the VyOS router, `192.168.10.1:9100` |
| `cancer-container` | cAdvisor on `192.168.100.3:9180`, with `sample_limit` 10,000 |
| `proxmox` | Proxmox exporter for `pve.monapona.de:443` |
| `blackbox-exporter` | the Blackbox Exporter itself |
| `vyos-icmp4`, `vyos-icmp6` | ICMP probes against the `.100` and `.200` addresses |
| `https_2xx` | HTTP probes against the web services, the list is in `monitoring/blackbox.nix` |

Dashboards and alerting rules are not declared in the repository.

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
