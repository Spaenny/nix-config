# Betrieb

## Voraussetzungen

- Nix mit den Features `nix-command` und `flakes`
- SSH-Zugang als `philipp` zu den Zielen, deren Namen `aquarius`, `blarm`, `dns-1` und `dns-2` auflösbar sein müssen
- für Secrets ein passender privater age-Schlüssel, siehe [Secrets](secrets.md)

`deploy` ist auf `bodenheizung` über das Home-Manager-Modul `cli.fish` installiert.

## Neue Dateien und Git

Ein Flake in einem Git-Repository sieht nur Dateien, die Git kennt. Eine neue Datei führt sonst zu Fehlern wie `path ... does not exist`, auch wenn sie auf der Platte liegt. Ein Commit ist dafür nicht nötig, es reicht:

```bash
git add -N <datei>     # Datei nur vormerken
```

Das gilt ebenso für neue verschlüsselte Dateien unter `secrets/`.

## Prüfen und bauen

```bash
nix flake check                                                       # Auswertung und deploy-rs-Checks
nix build .#nixosConfigurations.blarm.config.system.build.toplevel -L # einen Host bauen
nix build .#ente-server -L                                            # ein eigenes Paket bauen
nix fmt -- <datei>                                                    # Datei formatieren
nix fmt -- --check <datei>                                            # Format nur prüfen
```

`aquarius` lässt sich auf `bodenheizung` über die `binfmt`-Emulation bauen.

## Ausrollen

### bodenheizung (lokal)

```bash
nh os switch           # NH_FLAKE zeigt auf das Repository
nh os test             # aktivieren, ohne Boot-Eintrag anzulegen
```

Alternativ ohne `nh`:

```bash
sudo nixos-rebuild switch --flake .#bodenheizung
```

Einige Änderungen wirken erst nach einem Neustart, etwa Kernel-Parameter und `hardware.amdgpu.overdrive`.

### Server mit deploy-rs

| Ziel | Befehl | Fish-Alias |
| --- | --- | --- |
| `blarm` | `deploy .#blarm` | `nix-blarm` |
| `dns-1` und `dns-2` | `deploy --targets .#dns-1 .#dns-2` | `nix-dns` |
| `aquarius` | `deploy .#aquarius` | `nix-aquarius` |

Die Aliase verwenden den absoluten Pfad des Repositories und funktionieren daher aus jedem Verzeichnis.

Nützliche Parameter von `deploy`:

| Parameter | Wirkung |
| --- | --- |
| `--dry-activate` | Aktivierung nur simulieren |
| `--boot` | erst beim nächsten Neustart aktivieren |
| `-s`, `--skip-checks` | Flake-Checks überspringen |
| `--magic-rollback <bool>` | automatisches Zurückrollen bei Verbindungsverlust steuern |
| `--auto-rollback <bool>` | Zurückrollen bei fehlgeschlagener Aktivierung steuern |

Die Aktivierung läuft als `root`. Auf den Servern erlaubt `services.ssh.passwordlessDeploy` dafür `sudo` ohne Passwort, beschränkt auf die Aktivierungsprogramme von deploy-rs im Nix-Store und das Löschen seiner Canary-Dateien. Das Inventar setzt dazu `interactiveSudo = false`.

## Aktualisieren

```bash
nix flake update                # alle Inputs
nix flake update nixpkgs        # nur einen Input
```

Danach bauen oder prüfen und zuerst `bodenheizung` umschalten, dann die Server. Die Änderung an `flake.lock` üblicherweise als `chore(flake): update locked inputs` committen.

Eigene Pakete und Overlays sind fest gepinnt und werden nicht über `flake.lock` aktualisiert. Hier müssen Version, Revision und Hashes von Hand angepasst werden. Das betrifft `packages/`, `overlays/redlib-fixed`, `overlays/cinny`, das Plugin in `services.searxng` und `librewolf/markdown-viewer.nix`.

## CI

`.forgejo/workflows/main.yml` läuft bei jedem Push und Pull Request. Der Workflow installiert Nix und führt `nix flake check` aus. Er braucht einen Forgejo-Runner mit dem Label `ubuntu-latest-thingy`. Der Runner selbst ist nicht Teil dieses Repositories. Die CI rollt nichts aus.

## Git

- Commit-Nachrichten folgen Conventional Commits, zum Beispiel `feat(monitoring): …`, `fix(dns): …`, `chore(flake): …`.
- `origin` pusht gleichzeitig an drei Remotes, und `forgejo` zeigt auf die eigene Instanz.
- Commits werden standardmäßig mit OpenPGP signiert.

## Typische Änderungen

### Bestehendes Modul aktivieren

In `systems/<arch>/<host>/default.nix` eintragen und ausrollen:

```nix
${namespace}.services.paperless = enabled;
```

### Neues Modul

1. `modules/nixos/<bereich>/<name>/default.nix` nach dem [Muster](architektur.md#aufbau-eines-moduls) anlegen.
2. `git add -N` ausführen. Ein Eintrag in eine Liste ist nicht nötig.
3. Für Web-Dienste `mkNginxProxyHost` verwenden und `services.acme` aktivieren.
4. Das Modul im Host aktivieren.

Unterdateien wie `kanidm.nix` müssen per `imports` eingebunden werden. Ein Unterverzeichnis mit eigener `default.nix` wird dagegen automatisch geladen.

### Neuer OAuth2-Client in Kanidm

Beispiele sind `services/kanidm/proxmox.nix` für externe Anwendungen und `services/forgejo/kanidm.nix` für Dienste aus diesem Repository.

1. Secret `kanidm/oauth2/<name>/basic-secret` in `secrets/blarm-kanidm.yaml` ergänzen.
2. Datei mit `sops.secrets` und `services.kanidm.provision.systems.oauth2.<name>` schreiben, dazu eine Gruppe.
3. Die Datei in der `imports`-Liste des zuständigen Moduls ergänzen.

### Neuer Host

1. `systems/<arch>/<name>/default.nix` anlegen. Bei echter Hardware kommt `hardware-configuration.nix` dazu.
2. Den Host in `flake/inventory.nix` unter `nixosConfigurations` eintragen.
3. Für Deployments einen Eintrag in `deployNodes` ergänzen und im Host `services.ssh.passwordlessDeploy` setzen.
4. Falls der Host eigene Secrets braucht: seinen Schlüssel mit `ssh-to-age` ableiten, eine Regel in `.sops.yaml` ergänzen und `sops updatekeys` ausführen.

### Neues Paket

1. `packages/<name>/default.nix` anlegen.
2. Das Paket in `packageSet` in `flake/default.nix` eintragen. Pakete werden nicht automatisch erkannt.

### Neues Overlay

1. `overlays/<name>/default.nix` anlegen.
2. In `flake/default.nix` sowohl im Attributset `overlays` als auch in der Liste von `default` eintragen.

## Backups prüfen und wiederherstellen

NixOS legt auf `blarm` den Wrapper `restic-borgbase` an, der Repository und Passwort schon kennt:

```bash
sudo restic-borgbase snapshots
sudo restic-borgbase restore latest --target /data/restore --include /data/paperless
sudo systemctl start restic-backups-borgbase.service   # Backup sofort starten
```

`/tmp` eignet sich nicht als Ziel, denn es ist auf `blarm` ein tmpfs mit 50 % des RAM.

Für eine Wiederherstellung liegen die Quellen so:

- **PostgreSQL** (Forgejo, Ente): Dumps aus `/var/backup/postgresql`
- **Kanidm:** Online-Backups aus `/var/lib/kanidm/backups`
- **Alles andere:** Verzeichnisse unter `/data` und `/var/lib`

Vor dem Zurückspielen den betroffenen Dienst anhalten. Dieses Vorgehen ist hier nur beschrieben und wurde beim Schreiben der Dokumentation nicht durchgespielt.

## Fehlersuche

| Symptom | Ursache und Lösung |
| --- | --- |
| Nix findet eine neue Datei nicht | Sie ist nicht in Git erfasst, also `git add -N <datei>` |
| Secrets fehlen nach dem Booten | Die Identität ist nicht verfügbar. Für Hosts mit eigener `/home`-Partition `sops.ageKeyFile = null` setzen und den Host als Empfänger eintragen. |
| `sops` kann eine Datei nicht öffnen | Dem aktuellen Schlüssel fehlt die Berechtigung, oder die Datei braucht `sops updatekeys` |
| `deploy` fragt nach einem Passwort oder `sudo` scheitert | `services.ssh.passwordlessDeploy` ist auf dem Ziel noch nicht aktiv. Die Option muss einmal auf anderem Weg aktiviert werden, etwa mit `nixos-rebuild` auf dem Ziel. |
| Der Dienst übernimmt ein neues Secret nicht | Am Secret `restartUnits` setzen oder den Dienst von Hand neu starten |
| `lactd` startet nicht | LACT lehnt die erzeugte YAML ab. Das Modul schreibt sie darum von Hand statt über `services.lact.settings`. Die Konfiguration liegt unter `/etc/lact/config.yaml`. |
| llama-server läuft in einen OOM-Fehler | `contextLength` senken oder die Cache-Quantisierung prüfen, `gpuLayers` auf `null` lassen |
| NetBird meldet sich nicht an | Einheit `netbird-login` prüfen. Sie wiederholt fehlgeschlagene Anmeldungen alle 15 Sekunden. |
| Forgejo zeigt kein Kanidm-Login | Einheit `forgejo-kanidm-auth-source` prüfen |
