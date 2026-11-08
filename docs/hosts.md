# Hosts

Alle Hosts verwenden `nixos-unstable`, die `stateVersion` `24.11` und den Benutzer `philipp` mit Fish als Shell. Die Zeitzone ist `Europe/Berlin`.

Die Tabellen zeigen die wirksamen Module, also auch solche, die ein anderes Modul automatisch aktiviert.

## bodenheizung

Desktop mit KDE Plasma, Gaming, Virtualisierung und lokalem LLM. Datei: `systems/x86_64-linux/bodenheizung/`.

| Bereich | Aktive Module |
| --- | --- |
| `services` | `btrfs`, `hermes-agent`, `lact`, `llama-server`, `netbird`, `printer`, `ssh` |
| `system` | `fonts`, `fwupd`, `gnupg`, `gstreamer`, `nix-ld`, `secureboot`, `sops`, `tmpfs` |
| `cli` | `eza`, `kubernetes`, `neovim`, `nh` |
| `desktop` / `hardware` | `plasma` mit Remote Desktop / `apple`, `audio` |
| `games` / `networking` | `steam` / `wireguard` |

### Hardware und Boot

- AMD-CPU und AMD-GPU, Zen-Kernel, zram-Swap mit zstd
- Secure Boot über Lanzaboote mit eigenen sbctl-Schlüsseln plus den Microsoft-Schlüsseln (nötig für das Option-ROM der GPU und für Windows auf `sdb`)
- Btrfs auf LUKS mit den Subvolumes `root`, `home`, `nix`, `log` und `persist`. Root entsperrt sich mit einem der drei YubiKeys per FIDO2, ohne PIN und ohne Berühren; ohne Key kommt nach 5 s die Passwortabfrage.
- zweite verschlüsselte SSD unter `/data/ssd`, per `/etc/crypttab` mit einer Schlüsseldatei auf Root geöffnet (`nofail`, `discard`, 10 s Timeout)
- `binfmt`-Emulation für `aarch64-linux`, damit sich `aquarius` hier bauen lässt
- libvirt mit swtpm, außerdem Flatpak und TeamViewer

### GPU und lokales LLM

- `hardware.amdgpu.overdrive.enable` schaltet die Sysfs-Schnittstelle für LACT frei und wirkt erst nach einem Neustart.
- LACT regelt die Lüfterkurve und senkt die Kernspannung um 100 mV.
- `llama-server` läuft mit ROCm und dem Modell `underdog-saluki-27b`, Kontext 98.304 Token, KV-Cache `q4_0`, Layer-Offloading automatisch. Das Modell wird beim Start von Hugging Face geladen. Der Dienst ist bewusst über Port 8080 von außen erreichbar.
- Zed spricht den Server unter `http://localhost:8080` an. Der Modellname in `apps.zed-editor` muss zum `alias` des Servers passen.

### Netz

Offene Ports laut Auswertung:

| Protokoll | Ports | Zweck |
| --- | --- | --- |
| TCP | 22 | SSH |
| TCP | 3389 | KRdp (Remote Desktop) |
| TCP | 8080 | llama-server, lauscht auf `0.0.0.0` |
| TCP | 27036, 27037 | Steam Remote Play |
| TCP und UDP | 1714–1764 | KDE Connect |
| UDP | 5353 | mDNS (Avahi) |
| UDP | 10400, 10401, 27031–27036 | Steam Remote Play |
| UDP | 51820 | NetBird |

NetBird verbindet sich über einen Setup-Key mit `https://netbird.u0k.de`.

### Secrets

`sops.ageKeyFile = null`: Der Host entschlüsselt mit seinem SSH-Host-Key statt mit einem age-Schlüssel. `/home` ist beim Installieren der Secrets noch nicht eingehängt. Mehr dazu unter [Secrets](secrets.md#entschlüsselung-auf-den-hosts).

### Home-Manager

`homes/x86_64-linux/philipp@bodenheizung/default.nix` aktiviert:

| Bereich | Module |
| --- | --- |
| `cli` | `fish`, `git`, `home-manager`, `lazygit` |
| `apps` | `chatterino`, `discord`, `hermes-agent` (mit Dienst und Gateway), `kitty`, `libreoffice`, `librewolf`, `mpv`, `obs`, `signal-desktop`, `spotify`, `thunderbird`, `zed-editor` |
| `games` | `runelite` |
| `desktop` | `cursor`, `hotkeys`, `panel`, `spectacle` |

`apps.cinny` ist bewusst aus, weil es derzeit als unsicher gilt (libsoup). Außerdem setzt die Konfiguration bei jeder Aktivierung den Autostart von KRdp in `krdpserverrc` auf aus.

## blarm

Self-Hosting-Server als Proxmox-LXC-Container. Datei: `systems/x86_64-linux/blarm/default.nix`. Seine Dienste beschreibt [Dienste auf blarm](dienste.md).

| Bereich | Aktive Module |
| --- | --- |
| `services` | `acme`, `cinny`, `ente-auth`, `ente-server`, `forgejo`, `kanidm`, `linkwarden`, `monitoring`, `nginx`, `opencloud`, `paperless`, `restic`, `samba`, `searxng`, `ssh`, `syncthing` |
| `system` | `sops`, `tmpfs` |
| `cli` | `neovim` |

Offene Ports sind TCP 22, 80, 139, 443, 445 und 8384 sowie UDP 137 und 138. Als Nameserver sind `192.168.5.100`, `192.168.5.200` und ihre IPv6-Pendants eingetragen.

Die Daten liegen größtenteils unter `/data`. Dieses Verzeichnis ist im Repository nicht als Dateisystem deklariert, kommt also von außen, vermutlich als Proxmox-Mountpoint.

## dns

Eine Konfiguration für die beiden Proxmox-LXC-Container `dns-1` und `dns-2`. Datei: `systems/x86_64-linux/dns/default.nix`.

| Bereich | Aktive Module |
| --- | --- |
| `services` | `ssh`, `technitium-dns-server` |
| `system` | `tmpfs` |
| `cli` | `eza`, `neovim`, `nh` |

- Der Host verwendet keine Secrets und aktiviert sops nicht.
- Geöffnet sind TCP 22, 53, 80, 443, 853, 5380 und 53443 sowie UDP 53.
- Der Hostname wird nicht in Nix gesetzt, weil dieselbe Konfiguration für beide Instanzen gilt.
- Proxmox erzeugt die systemd-networkd-Dateien mit `IPv6AcceptRA=false`, was SLAAC verhindert. Ein Drop-in unter `/etc/systemd/network/net0.network.d/` überschreibt nur diese Einstellung. Dabei bleiben die von Proxmox verwalteten Adressen unberührt.

## aquarius

Technitium-DNS-Server auf einem aarch64-Board, das von einem SD-Karten-Image startet. Dateien: `systems/aarch64-linux/aquarius/`.

| Bereich | Aktive Module |
| --- | --- |
| `services` | `ssh`, `technitium-dns-server` |
| `system` | `sops` |
| `cli` | `neovim` |

- Boot über extlinux statt GRUB
- Netz über systemd-networkd: `end0` per DHCP, `wg*`-Schnittstellen bleiben unverwaltet
- SSH ohne Passwort-Login und ohne Root-Login
- `sops` ist aktiv, deklariert aber derzeit keine Secrets
- gleiche offene Ports wie `dns`
