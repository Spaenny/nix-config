# Dokumentation der NixOS-Konfiguration

Dieses Repository beschreibt vier NixOS-Konfigurationen als Nix-Flake: einen Desktop, einen Self-Hosting-Server und die DNS-Server des Heimnetzes. Für den Desktop kommt eine Home-Manager-Konfiguration dazu.

Stand: 2026-11-06. Die Angaben zu aktiven Modulen, Ports und virtuellen Hosts sind per `nix eval` gegen den damaligen Arbeitsbaum geprüft, einschließlich der noch nicht committeten Änderungen.

## Inhalt

| Dokument | Thema |
| --- | --- |
| [Architektur](architektur.md) | Aufbau des Flakes, Modulsystem, Hilfsfunktionen, Overlays und Pakete |
| [Hosts](hosts.md) | Die Maschinen und was auf ihnen aktiv ist |
| [Dienste auf blarm](dienste.md) | Domains, Ports, Daten, Single Sign-on, Monitoring und Backups |
| [Modulreferenz](module.md) | Alle NixOS- und Home-Manager-Module mit ihren Optionen |
| [Secrets](secrets.md) | Umgang mit sops-nix und age |
| [Betrieb](betrieb.md) | Deployen, Aktualisieren, CI und typische Änderungen |
| [Offene Punkte](offene-punkte.md) | Auffälligkeiten, die beim Dokumentieren aufgefallen sind |

## Die Hosts auf einen Blick

| Host | Architektur | Rolle | Ausrollen |
| --- | --- | --- | --- |
| `bodenheizung` | x86_64 | Desktop mit KDE Plasma, Gaming und lokalen LLMs | lokal mit `nh os switch` |
| `blarm` | x86_64, Proxmox-LXC | Self-Hosting-Server | `deploy .#blarm` |
| `dns` (`dns-1`, `dns-2`) | x86_64, Proxmox-LXC | Technitium-DNS-Server, eine Konfiguration für zwei Instanzen | `deploy --targets .#dns-1 .#dns-2` |
| `aquarius` | aarch64, SD-Karten-Image | Technitium-DNS-Server | `deploy .#aquarius` |

## Schnellstart

```bash
nix flake check                     # Konfiguration prüfen (läuft auch in der CI)
nix fmt -- <datei>                  # Nix-Datei mit nixfmt formatieren
nh os switch                        # bodenheizung lokal umschalten
deploy .#blarm                      # Server ausrollen
```

Neue Dateien müssen Git bekannt sein, bevor Nix sie sieht: Ein Flake in einem Git-Repository wertet nur erfasste Dateien aus. Details stehen unter [Betrieb](betrieb.md#neue-dateien-und-git).
