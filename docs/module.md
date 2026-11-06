# Modulreferenz

Alle Optionen liegen unter `awesome-flake.`, das hier weggelassen ist. Wenn nichts anderes angegeben ist, hat ein Modul nur die Option `enable`, und sie steht auf `false`.

Die Spalte **Host** nennt, wo ein Modul wirksam aktiv ist: `B` für `bodenheizung`, `L` für `blarm`, `D` für `dns`, `A` für `aquarius`. Bei Home-Manager-Modulen bezieht sie sich auf `philipp@bodenheizung`.

## NixOS: Dienste (`services.*`)

| Modul | Host | Zweck | Weitere Optionen (Standardwert) |
| --- | --- | --- | --- |
| `acme` | L | Wildcard-Zertifikat `stahl.sh` über PowerDNS | – |
| `btrfs` | B | automatischer Scrub und fstrim | – |
| `cinny` | L | Matrix-Client als statische Seite | `domain` (`cinny.stahl.sh`), `package`, `nginx.enable` (`true`) |
| `ente-auth` | L | Web-Oberfläche von Ente Auth | `domain` (`ente.stahl.sh`), `apiEndpoint` (`https://ente.stahl.sh/api`), `package`, `nginx.enable` (`true`) |
| `ente-server` | L | Ente-Backend | `domain`, `port` (6789), `dataDir` (`/data/ente`), `secretsFile`, `database.name`, `database.user` (je `ente`), `package`, `nginx.enable` (`true`) |
| `forgejo` | L | Git-Hosting | `domain` (`git.stahl.sh`), `ssh_domain` (`stahl.sh`), `port` (3001), `user` (`forgejo`), `package`, `nginx.enable` (`true`) |
| `hermes-agent` | B | Secret und Linger für den Hermes-Benutzerdienst | `user` (`philipp`), `secretName` (`hermes-env`), `secretFile` (`bodenheizung-hermes.env`) |
| `kanidm` | L | Identitätsanbieter | `domain` (`id.stahl.sh`), `managedDomain` (`stahl.sh`), `bindAddress` (`127.0.0.1:8443`), `acmeHost` (`stahl.sh`), `adminUser.name` (`philipp`), `secretsFile`, `backup.versions` (7), `backup.schedule` (`30 22 * * *`), `package`, `nginx.enable` (`true`) |
| `lact` | B | GPU-Lüfterkurve und Undervolting | `gpuId` (Pflicht), `fanCurve` (`1000:70,2000:85,3000:100`), `maxRpm` (3000), `voltageOffset` (`null`) |
| `linkwarden` | L | Lesezeichen | `domain` (`link.stahl.sh`), `host` (`0.0.0.0`), `port` (3000), `package`, `nginx.enable` (`true`) |
| `llama-server` | B | lokales LLM mit llama.cpp | siehe [unten](#llama-server) |
| `monitoring` | L | Prometheus, Grafana und Exporter | `instance` (Hostname), `statsDomain` (`stats.stahl.sh`) |
| `netbird` | B | NetBird-Client mit Setup-Key | `managementUrl` (`https://netbird.u0k.de`), `setupKeySecret` (`bodenheizung-netbird.key`) |
| `nginx` | L | nginx mit TLS-Fallback-Host | – |
| `ollama` | – | Ollama-Server | `models` (`[]`), `syncModels` (`false`), `acceleration` (`rocm`), `keepAlive` (`30m`) |
| `opencloud` | L | Dateiablage mit Collabora | `domain` (`cloud.stahl.sh`), `collaboraDomain` (`collabora.stahl.sh`), `wopiDomain` (`wopiserver.stahl.sh`), `dataDir` (`/data/opencloud`) |
| `paperless` | L | Dokumentenverwaltung | `domain` (`paperless.stahl.sh`), `port` (28981), `package`, `nginx.enable` (`true`) |
| `printer` | B | CUPS mit HPLIP und Avahi | – |
| `restic` | L | Backup und PostgreSQL-Dumps | – |
| `samba` | L | Share auf OpenCloud-Daten | `shareName` (`opencloud`), `path`, `user` (`philipp`) |
| `searxng` | L | Metasuche und Redlib | siehe [unten](#searxng) |
| `ssh` | alle | OpenSSH und autorisierte Schlüssel | `keys` (die Schlüssel `mobile` und `arbeit`), `passwordlessDeploy` (`false`) |
| `syncthing` | L | Dateisynchronisation | `ip` (`192.168.10.3`), `port` (8384), `openDefaultPorts` (`false`) |
| `technitium-dns-server` | D, A | DNS-Server | `package`, `openFirewall` (`true`), `firewallUDPPorts`, `firewallTCPPorts` |

### llama-server

| Option | Standardwert | Bedeutung |
| --- | --- | --- |
| `acceleration` | `rocm` | Backend: `rocm`, `vulkan`, `cuda` oder `cpu` |
| `hf` | `unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M` | Hugging-Face-Modell, hat Vorrang vor `model` |
| `model` | Pfad unter `/home/philipp/.llama/` | lokale GGUF-Datei, gilt nur mit `hf = null` |
| `alias` | `null` | Modellname in der API. Ohne `hf` ist der Standard der Dateiname ohne `.gguf`. |
| `contextLength` | 32768 | Kontextgröße in Token |
| `cacheTypeK`, `cacheTypeV` | `q4_0` | Quantisierung des KV-Caches |
| `flashAttn` | `auto` | `on`, `off` oder `auto` |
| `gpuLayers` | `null` | `null` verteilt die Layer automatisch auf den VRAM |
| `modelDraft`, `gpuLayersDraft`, `specType` | `null` | spekulatives Dekodieren |
| `mmproj` | `null` | Projektor-GGUF für Bilderkennung |
| `host`, `port` | `127.0.0.1`, 8080 | Lauschadresse |
| `openFirewall` | `true` | öffnet den Port |
| `extraSettings` | `{ }` | weitere Argumente von `llama-server` |

Der Dienst läuft mit `DynamicUser`. Pfade unter `/home/` bindet das Modul deshalb schreibgeschützt nach `/var/lib/llama-cpp` ein.

### searxng

| Option | Standardwert | Bedeutung |
| --- | --- | --- |
| `domain` | `search.stahl.sh` | Domain der Suche |
| `nginx.enable` | `true` | Reverse Proxy |
| `redlib.enable` | `true` | Redlib starten und Reddit-Links umschreiben |
| `redlib.domain` | `reddit.stahl.sh` | Domain von Redlib |
| `aiAnswers.enable` | `false` | Plugin AI Answers einbauen |
| `aiAnswers.provider` | `ollama` | `openrouter`, `openai`, `ollama`, `localai`, `lmstudio`, `gemini`, `azure` oder `huggingface` |
| `aiAnswers.model`, `aiAnswers.url` | `null` | werden als `LLM_MODEL` und `LLM_URL` gesetzt |

## NixOS: System (`system.*`)

| Modul | Host | Zweck | Weitere Optionen (Standardwert) |
| --- | --- | --- | --- |
| `fonts` | B | Schriften und Emoji | `emoji` (`false`), `fonts` (`[]`) |
| `fwupd` | B | Firmware-Updates | – |
| `gnupg` | B | GnuPG-Agent mit `pinentry-qt`, ohne SSH-Unterstützung | – |
| `gstreamer` | B | GStreamer mit Plugins | – |
| `nix-ld` | B | fremde, dynamisch gelinkte Programme ausführen | – |
| `sops` | B, L, A | sops-nix | `secretsDir` (`secrets/`), `ageKeyFile` (`~philipp/.config/sops/age/keys.txt`) |
| `tmpfs` | B, L, D | `/tmp` als tmpfs mit 50 % des RAM | – |

Das Modul `tmpfs` liegt im Verzeichnis `modules/nixos/system/tmp`.

## NixOS: Kommandozeile (`cli.*`)

| Modul | Host | Zweck | Weitere Optionen (Standardwert) |
| --- | --- | --- | --- |
| `eza` | B, D | installiert eza | – |
| `kubernetes` | B | installiert die Client-Konfigurationen für `kubectl` und `talosctl` aus sops und setzt `KUBECONFIG` und `TALOSCONFIG` | `user` (`philipp`), `kubeconfigFile`, `talosconfigFile` |
| `neovim` | alle | Neovim über nvf | – |
| `nh` | B, D | `nh` mit automatischer Bereinigung (`--keep-since 4d --keep 3`) | – |

Das Modul `kubernetes` installiert nur die Konfigurationsdateien, nicht die Programme selbst. Die Dateien unter `/run/secrets` sind schreibgeschützt. Befehle wie `kubectl config use-context` brauchen deshalb einen expliziten Pfad zu einer beschreibbaren Datei.

### Neovim

Die Basis setzt die Leader-Taste auf `Space`, relative Zeilennummern, die Einrückung von 2 Leerzeichen und die System-Zwischenablage. Die Untermodule ergänzen:

| Untermodul | Inhalt |
| --- | --- |
| `cmp` | Vervollständigung mit nvim-cmp |
| `git` | gitsigns, Tastenkürzel unter `<leader>h` |
| `lsp` | LSP, Format beim Speichern, Treesitter und die Sprachen Bash, Fish, Go, JSON, Markdown, Nix (nixfmt), Python (ruff), Rust, TOML, YAML |
| `lualine` | Statuszeile |
| `neo-tree` | Dateibaum, Umschalten mit `<leader>e` |
| `rainbow-delimiters` | farbige Klammern |
| `surround` | mini.surround |
| `telescope` | Fuzzy-Suche |
| `theme` | Tokyo Night in der Variante `night` |
| `which-key` | Tastenkürzel-Hilfe |

## NixOS: Desktop, Hardware, Netz, Spiele

| Option | Host | Zweck | Weitere Optionen (Standardwert) |
| --- | --- | --- | --- |
| `desktop.plasma` | B | Plasma 6, SDDM mit Autologin, NetworkManager, KDE Connect | `extraExcludePackages` (`[]`), `remoteDesktop.*` (siehe unten) |
| `hardware.apple` | B | usbmuxd und libimobiledevice für iOS-Geräte | – |
| `hardware.audio` | B | PipeWire mit Null-Sink und Loopback für das Scarlett 2i2 | `extra-packages` (`[]`) |
| `networking.wireguard` | B | WireGuard-Unterstützung | – |
| `games.steam` | B | Steam, Proton GE, Gamescope, GameMode, MangoHud | – |

Optionen von `desktop.plasma.remoteDesktop`:

| Option | Standardwert |
| --- | --- |
| `enable` | `false` |
| `port` | 3389 |
| `openFirewall` | `true` |
| `monitor` | 0 |
| `disableH264` | `true`, wegen der Kompatibilität mit Windows-RDP |
| `usePlasmaProtocol` | `true` |

## Home-Manager: Kommandozeile (`cli.*`)

| Modul | Host | Zweck | Weitere Optionen (Standardwert) |
| --- | --- | --- | --- |
| `fish` | B | Fish, Plugins, zoxide, eza, deploy-rs und Deploy-Aliase | – |
| `git` | B | Git mit LFS und OpenPGP-Signatur | `signingKey` (`0F21E3C3`), `signByDefault` (`true`) |
| `home-manager` | B | Home-Manager-Programm | – |
| `lazygit` | B | lazygit | – |
| `neovim` | – | `EDITOR`, Alias `vimdiff` und `less`. Neovim selbst kommt nur dazu, wenn das System kein nvf aktiviert hat. | – |

Name und E-Mail für Git kommen aus `user.name` und `user.email`. Die Fish-Aliase `nix-aquarius`, `nix-blarm` und `nix-dns` rufen deploy-rs auf. `cd` ist ein Alias für `z`.

## Home-Manager: Anwendungen (`apps.*`)

| Modul | Host | Zweck | Weitere Optionen |
| --- | --- | --- | --- |
| `chatterino` | B | Twitch-Chat | – |
| `cinny` | – | Matrix-Client als Desktop-App | – |
| `discord` | B | Discord | – |
| `hermes-agent` | B | KI-Agent, siehe unten | `extraPackages`, `service.enable`, `service.gateway`, `service.secretName` |
| `kitty` | B | Terminal mit Tokyo Night | `settings`, `font`, `plasma.enable` (Kürzel `Meta+Return`) |
| `libreoffice` | B | LibreOffice | – |
| `librewolf` | B | Browser, siehe unten | `extraConfig`, `userChrome`, `settings`, `extensions.packages`, `search` |
| `mpv` | B | mpv und Haruna | – |
| `obs` | B | OBS mit Plugins | – |
| `photocraft` | – | Bildbearbeitung | – |
| `signal-desktop` | B | Signal | – |
| `spotify` | B | Spotify | – |
| `thunderbird` | B | Thunderbird | – |
| `zed-editor` | B | Zed, siehe unten | – |

**hermes-agent:** Mit `service.enable` gehört `~/.hermes` Nix. `hermes config set` schreibt dann nicht mehr, und `config.yaml` wird bei jeder Aktivierung zusammengeführt. `service.gateway` setzt `service.enable` voraus. Einziger Anbieter ist Cortecs, der API-Schlüssel kommt aus dem Secret `hermes-env`, das das gleichnamige NixOS-Modul bereitstellt. Dessen `secretName` muss mit dem hier übereinstimmen.

**librewolf:** Standardsuche ist SearXNG unter `search.stahl.sh`. Die Erweiterungen kommen aus `firefox-addons` und sind Bitwarden, Redirector, Return YouTube Dislike, SponsorBlock, uBlock Origin und 7TV. Markdown Viewer ist lokal paketiert, weil es dort fehlt. Die Passwortspeicherung ist aus. Die Erweiterungsliste ist auf `x86_64-linux` festgelegt.

**zed-editor:** Eingerichtet sind das lokale llama.cpp und Cortecs, Standard ist Cortecs mit `glm-5.3-flash`. Der Vim-Modus ist an. Die Agenten-Einstellungen `allow_unsandboxed` und `always_allow_tool_actions` sind aktiv: Der Agent führt Werkzeugaktionen ohne Rückfrage aus und darf Terminalbefehle außerhalb der Sandbox starten.

## Home-Manager: Desktop und Spiele

| Option | Host | Zweck |
| --- | --- | --- |
| `desktop.cursor` | B | Cursor-Theme Rosé Pine, Größe 32 |
| `desktop.hotkeys` | B | Fenster schließen mit `Meta+Shift+Q` |
| `desktop.panel` | B | Plasma-Panel oben auf den Bildschirmen 1 und 3 |
| `desktop.spectacle` | B | Bereichs-Screenshot mit `Meta+Shift+S` |
| `games.runelite` | B | RuneLite und Bolt Launcher |
