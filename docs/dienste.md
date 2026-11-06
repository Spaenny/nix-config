# Dienste auf blarm

## Übersicht

Alle öffentlichen Domains laufen über nginx mit dem Wildcard-Zertifikat für `stahl.sh`. Ein Fallback-Host `_` antwortet auf unbekannte Hostnamen mit 404, damit solche Anfragen nicht beim ersten Anwendungs-Host landen.

| Domain | Dienst | Lokaler Port | Daten | Datenbank |
| --- | --- | --- | --- | --- |
| `git.stahl.sh` | Forgejo | 3001 | `/var/lib/forgejo` | PostgreSQL |
| `id.stahl.sh` | Kanidm | 8443 (TLS) | `/var/lib/kanidm` | intern |
| `stats.stahl.sh` | Grafana | 3002 | Standardpfad | intern |
| `collector.stahl.sh` | Prometheus mit Basic Auth | 9090 | Standardpfad | intern |
| `cloud.stahl.sh` | OpenCloud | 9200 | `/data/opencloud` | intern |
| `collabora.stahl.sh` | Collabora Online | 9980 | – | – |
| `wopiserver.stahl.sh` | OpenCloud WOPI | 9300 | – | – |
| `ente.stahl.sh` | Ente Auth, Web und API unter `/api/` | 6789 | `/data/ente` | PostgreSQL |
| `link.stahl.sh` | Linkwarden | 3000 | Standardpfad | Standard des Upstream-Moduls |
| `paperless.stahl.sh` | Paperless-ngx | 28981 | `/data/paperless` | SQLite |
| `search.stahl.sh` | SearXNG | 1340 | – | – |
| `reddit.stahl.sh` | Redlib | 1341 | – | – |
| `cinny.stahl.sh` | Cinny, statische Dateien | – | – | – |

### Weitere Ports

| Port | Dienst | Bindung |
| --- | --- | --- |
| 139, 445 (TCP), 137, 138 (UDP) | Samba | Firewall offen, Zugriff auf `192.168.1.0/24` beschränkt |
| 8384 | Syncthing-Oberfläche | `192.168.10.3`, Firewall offen |
| 9100 | Node Exporter | lokal |
| 9101 | OpenCloud-Web | lokal |
| 9116 | Blackbox Exporter | lokal |
| 9221 | Proxmox Exporter | lokal |
| 9233 | OpenCloud-Registry (NATS) | lokal |

Die Ports 9100 und 9115 sind belegt beziehungsweise von OpenCloud beansprucht. Deshalb liegt OpenCloud-Web auf 9101 und der Blackbox Exporter auf 9116.

## TLS-Zertifikat

`services.acme` beantragt `stahl.sh` und `*.stahl.sh` per DNS-Challenge über PowerDNS. Die Zugangsdaten stehen in `secrets/blarm-acme.env`. Sowohl nginx als auch Kanidm sind Mitglied der Gruppe `acme`, denn Kanidm verwendet das Zertifikat direkt für sein eigenes TLS.

## Single Sign-on mit Kanidm

Kanidm ist der Identitätsanbieter. Benutzer, Gruppen und OAuth2-Clients werden deklariert. Der Admin-Benutzer heißt `philipp`.

| Client | Herkunft | Gruppe |
| --- | --- | --- |
| Forgejo | `https://git.stahl.sh` | `forgejo_users` |
| Grafana | `https://stats.stahl.sh` | `grafana_users`, Adminrechte über `grafana_admins` |
| Home Assistant | `https://ha.monapona.de` | `home_assistant_users` |
| Immich | `https://im.monapona.de` | `immich_users` |
| Proxmox | `https://pve.monapona.de` | `proxmox_users` |

Home Assistant, Immich und Proxmox laufen nicht auf `blarm`. Hier liegt nur ihre Client-Registrierung.

Einzelheiten:

- Alle Gruppen setzen `overwriteMembers = false`, sodass manuell hinzugefügte Mitglieder erhalten bleiben.
- Name und E-Mail des Admins liegen als Secret vor und werden über das Template `kanidm-provision-extra.json` eingespielt.
- Die Oneshot-Unit `forgejo-kanidm-auth-source` legt die Anmeldequelle in Forgejo an oder aktualisiert sie.
- Grafana vergibt die Rolle `GrafanaAdmin` über den Claim `grafana_role`, alle anderen Benutzer sind `Viewer`.

## Monitoring

Prometheus (Aufbewahrung 15 Tage) und Grafana laufen lokal. Prometheus ist in Grafana als Standard-Datenquelle fest hinterlegt. Von außen ist Prometheus über `collector.stahl.sh` mit Basic Auth erreichbar.

| Job | Ziel |
| --- | --- |
| `prometheus` | sich selbst |
| `node` | Node Exporter auf `blarm`, inklusive systemd-Collector |
| `vyos-node` | Node Exporter des VyOS-Routers, `192.168.10.1:9100` |
| `cancer-container` | cAdvisor auf `192.168.100.3:9180`, mit `sample_limit` 10.000 |
| `proxmox` | Proxmox-Exporter für `pve.monapona.de:443` |
| `blackbox-exporter` | der Blackbox Exporter selbst |
| `vyos-icmp4`, `vyos-icmp6` | ICMP-Proben gegen die Adressen `.100` und `.200` |
| `https_2xx` | HTTP-Proben gegen die Web-Dienste, die Liste steht in `monitoring/blackbox.nix` |

Dashboards und Alarmregeln sind im Repository nicht deklariert.

## Backups

Alle Aufträge laufen nachts:

| Zeit | Auftrag | Ablage |
| --- | --- | --- |
| 22:30 | Kanidm-Online-Backup, 7 Versionen | `/var/lib/kanidm/backups` |
| 23:30 | PostgreSQL-Dump aller Datenbanken | `/var/backup/postgresql` |
| 00:10 + bis zu 1 h Zufall | Restic-Backup `borgbase` | externes Repository, die URL steht im Secret |

Restic sichert `/home`, `/var/lib`, `/data` und die PostgreSQL-Dumps. Ausgenommen sind `/home/*/.cache`, `/data/lost+found`, `/var/lib/containers` und `/var/lib/docker`.

- **Aufbewahrung:** 7 täglich, 4 wöchentlich, 6 monatlich, 2 jährlich
- **Prüfung:** `--read-data-subset=5%`

Die anderen Hosts haben in dieser Konfiguration kein Backup. Wie man Daten zurückholt, steht unter [Betrieb](betrieb.md#backups-prüfen-und-wiederherstellen).

## Hinweise zu einzelnen Diensten

**Forgejo:** Die Dateien aus `codeberg-themes` werden vor jedem Start von einer Oneshot-Unit nach `/var/lib/forgejo/custom/public/assets` kopiert. Standard-Theme ist `codeberg-dark`. SSH-Klone laufen über `stahl.sh` statt über `git.stahl.sh`. Das Modul schaltet außerdem Docker ein.

**OpenCloud:** Der Dienst setzt das Mount-Unit `data.mount` voraus und startet ohne `/data` nicht. Die Konfiguration unter `/data/opencloud/config` ist für den Hauptdienst nur lesbar. Collabora läuft im `home_mode` ohne eigenes TLS hinter nginx.

**Samba:** Der Share `opencloud` zeigt direkt auf den Speicherpfad eines OpenCloud-Benutzers. Der Pfad enthält dessen UUID und ist im Modul fest eingetragen. Der Samba-Benutzer `philipp` schreibt dort als `opencloud`.

**Ente:** Der Server nutzt PostgreSQL per Peer-Authentifizierung, deshalb müssen Datenbankname und Benutzer übereinstimmen. Das prüft eine Assertion. Die Zugangsdaten rendert sops-nix als `ente-server-credentials.yaml`. Es läuft nur Ente Auth, ein S3-Abschnitt ist nicht nötig.

**SearXNG:** Der Wert `secret_key` in der Konfiguration ist ein Platzhalter, den echten Wert liefert `secrets/blarm-searxng.env`. Das Plugin AI Answers wird beim Bau in das Paket kopiert und nutzt auf `blarm` den Provider `ollama` mit dem Modell `gemma3:4b`. Der Ollama-Server läuft extern auf `192.168.10.201`, die Adresse kommt als `LLM_URL` aus `secrets/blarm-searxng.env`. Links zu Reddit werden auf `reddit.stahl.sh` umgeschrieben.

**Paperless:** Die OCR-Sprachen sind Deutsch und Englisch.

**Linkwarden:** Der Dienst lauscht standardmäßig auf `0.0.0.0:3000`. Die Firewall öffnet nur 80 und 443.
