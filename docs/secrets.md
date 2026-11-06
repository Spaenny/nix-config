# Secrets

Secrets werden mit [sops](https://github.com/getsops/sops) und age verschlüsselt im Verzeichnis `secrets/` abgelegt. [sops-nix](https://github.com/Mic92/sops-nix) entschlüsselt sie beim Aktivieren eines Hosts nach `/run/secrets`. Der Nix-Store enthält damit nur die verschlüsselten Dateien.

Diese Dokumentation enthält bewusst keine Inhalte von Secrets. Beim Schreiben wurden nur die Dateinamen und die Schlüsselnamen aus dem Nix-Code gelesen.

## Empfänger

`.sops.yaml` legt fest, wer eine Datei entschlüsseln kann. Es gilt die erste passende Regel:

| Dateien | Empfänger |
| --- | --- |
| `secrets/bodenheizung-*.{env,yaml,key}` | `primary` und `bodenheizung` |
| alle anderen `secrets/*.{env,yaml,key}` | `primary` |

Andere Dateiendungen passen auf keine Regel.

## Entschlüsselung auf den Hosts

Das Modul `system.sops` wählt die Identität über die Option `ageKeyFile`:

| Wert | Identität | Verwendet von |
| --- | --- | --- |
| Standard | `~philipp/.config/sops/age/keys.txt` | `blarm`, `aquarius` |
| `null` | SSH-Host-Key `/etc/ssh/ssh_host_ed25519_key` | `bodenheizung` |

Ein Host kann nur Secrets lesen, für die seine Identität Empfänger ist. `blarm` braucht deshalb den privaten `primary`-Schlüssel an diesem Pfad.

`bodenheizung` nutzt den Host-Key, weil sops-nix die Secrets früh in der Aktivierung installiert. Zu diesem Zeitpunkt ist die eigene `/home`-Partition beim Booten noch nicht eingehängt, ein Schlüssel darunter fehlt also, und alle Secrets des Hosts würden scheitern.

## Dateien

| Datei | Verwendet von |
| --- | --- |
| `blarm-acme.env` | `services.acme` |
| `blarm-ente-server.yaml` | `services.ente-server` |
| `blarm-kanidm.yaml` | `services.kanidm` und die OAuth2-Clients von Forgejo und Grafana |
| `blarm-linkwarden.env` | `services.linkwarden` |
| `blarm-monitoring.yaml` | `services.monitoring` (Grafana, Prometheus) |
| `blarm-pve-exporter.yaml` | `services.monitoring` (Proxmox-Exporter) |
| `blarm-restic.yaml` | `services.restic` |
| `blarm-searxng.env` | `services.searxng` |
| `bodenheizung-hermes.env` | `services.hermes-agent` |
| `bodenheizung-kubeconfig.yaml` | `cli.kubernetes` |
| `bodenheizung-netbird.key` | `services.netbird` |
| `bodenheizung-talosconfig.yaml` | `cli.kubernetes` |

## Secrets bearbeiten

Dafür braucht man einen passenden privaten Schlüssel:

```bash
sops secrets/blarm-restic.yaml          # bearbeiten
sops updatekeys secrets/<datei>         # Empfänger nach Änderung an .sops.yaml aktualisieren
```

Danach muss der betroffene Host neu ausgerollt werden. Einheiten mit `restartUnits` starten bei einer Änderung des Secrets automatisch neu.

## Secrets im Nix-Code verwenden

Der Pfad zum Secret-Verzeichnis kommt immer aus `system.sops.secretsDir`. Das Modul aktiviert sops selbst:

```nix
let
  sopsCfg = config.${namespace}.system.sops;
in
{
  ${namespace}.system.sops = enabled;

  # Einzelner Wert aus einer YAML-Datei
  sops.secrets.restic_password = mkSopsSecret sopsCfg.secretsDir "blarm-restic.yaml" {
    format = "yaml";
    key = "restic/password";
  };

  # Ganze Dotenv-Datei
  sops.secrets.linkwarden = mkSopsDotenvSecret sopsCfg.secretsDir "blarm-linkwarden.env";
}
```

Das Repository nutzt diese Muster:

| Muster | Beispiel | Hinweis |
| --- | --- | --- |
| einzelner Wert | `services.restic` | `format = "yaml"` und `key` |
| Dotenv | `services.linkwarden` | für `environmentFile` |
| ganze Datei | `cli.kubernetes` | `key = ""` installiert die ganze entschlüsselte Datei |
| Binärdatei | `services.netbird` | `format = "binary"` |
| Template | `services.ente-server` | `sops.templates` setzt Secrets über `config.sops.placeholder` in eine Datei ein |
| Datei-Referenz | `services.monitoring` | Grafana liest den Wert über `$__file{...}` |

Grundsätze:

- Secret-Werte nie direkt in Nix-Ausdrücke schreiben, denn sonst landen sie lesbar im Nix-Store. Immer den Pfad übergeben, also `config.sops.secrets.<name>.path`.
- Mit `owner`, `group` und `mode` nur dem Dienst Zugriff geben, der das Secret braucht. Ohne diese Angaben gehört die Datei `root`.
- Mit `restartUnits` dafür sorgen, dass der Dienst ein geändertes Secret übernimmt.
