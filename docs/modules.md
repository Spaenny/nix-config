# Module reference

All options live under `awesome-flake.`, which is omitted here. Unless stated otherwise, a module only has the `enable` option, and it defaults to `false`.

The **Host** column shows where a module is effectively active: `B` for `bodenheizung`, `L` for `blarm`, `D` for `dns`, `A` for `aquarius`. For Home Manager modules it refers to `philipp@bodenheizung`.

## NixOS: services (`services.*`)

| Module | Host | Purpose | Other options (default) |
| --- | --- | --- | --- |
| `acme` | L | wildcard certificate `stahl.sh` via PowerDNS | – |
| `btrfs` | B | automatic scrub and fstrim | – |
| `cinny` | L | Matrix client as a static site | `domain` (`cinny.stahl.sh`), `package`, `nginx.enable` (`true`) |
| `ente-auth` | L | Ente Auth web interface | `domain` (`ente.stahl.sh`), `apiEndpoint` (`https://ente.stahl.sh/api`), `package`, `nginx.enable` (`true`) |
| `ente-server` | L | Ente backend | `domain`, `port` (6789), `dataDir` (`/data/ente`), `secretsFile`, `database.name`, `database.user` (both `ente`), `package`, `nginx.enable` (`true`) |
| `forgejo` | L | Git hosting | `domain` (`git.stahl.sh`), `ssh_domain` (`stahl.sh`), `port` (3001), `user` (`forgejo`), `package`, `nginx.enable` (`true`) |
| `hermes-agent` | B | secret and linger for the Hermes user service | `user` (`philipp`), `secretName` (`hermes-env`), `secretFile` (`bodenheizung-hermes.env`) |
| `kanidm` | L | identity provider | `domain` (`id.stahl.sh`), `managedDomain` (`stahl.sh`), `bindAddress` (`127.0.0.1:8443`), `acmeHost` (`stahl.sh`), `adminUser.name` (`philipp`), `secretsFile`, `backup.versions` (7), `backup.schedule` (`30 22 * * *`), `package`, `nginx.enable` (`true`) |
| `lact` | B | GPU fan curve and undervolting | `gpuId` (required), `fanCurve` (`1000:70,2000:85,3000:100`), `maxRpm` (3000), `voltageOffset` (`null`) |
| `linkwarden` | L | bookmarks | `domain` (`link.stahl.sh`), `host` (`0.0.0.0`), `port` (3000), `package`, `nginx.enable` (`true`) |
| `llama-server` | B | local LLM with llama.cpp | see [below](#llama-server) |
| `monitoring` | L | Prometheus, Grafana and exporters | `instance` (hostname), `statsDomain` (`stats.stahl.sh`) |
| `netbird` | B | NetBird client with setup key | `managementUrl` (`https://netbird.u0k.de`), `setupKeySecret` (`bodenheizung-netbird.key`) |
| `nginx` | L | nginx with TLS fallback host | – |
| `opencloud` | L | file storage with Collabora | `domain` (`cloud.stahl.sh`), `collaboraDomain` (`collabora.stahl.sh`), `wopiDomain` (`wopiserver.stahl.sh`), `dataDir` (`/data/opencloud`) |
| `paperless` | L | document management | `domain` (`paperless.stahl.sh`), `port` (28981), `package`, `nginx.enable` (`true`) |
| `printer` | B | CUPS with HPLIP and Avahi | – |
| `restic` | L | backups and PostgreSQL dumps | – |
| `samba` | L | share on OpenCloud data | `shareName` (`opencloud`), `path`, `user` (`philipp`) |
| `searxng` | L | metasearch and Redlib | see [below](#searxng) |
| `ssh` | all | OpenSSH and authorized keys | `keys` (the `mobile` and `arbeit` keys), `passwordlessDeploy` (`false`) |
| `syncthing` | L | file synchronization | `ip` (`192.168.10.3`), `port` (8384), `openDefaultPorts` (`false`) |
| `technitium-dns-server` | D, A | DNS server | `package`, `openFirewall` (`true`), `firewallUDPPorts`, `firewallTCPPorts` |

### llama-server

| Option | Default | Meaning |
| --- | --- | --- |
| `acceleration` | `rocm` | backend: `rocm`, `vulkan`, `cuda` or `cpu` |
| `hf` | `unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M` | Hugging Face model, takes precedence over `model` |
| `model` | path under `/home/philipp/.llama/` | local GGUF file, only used with `hf = null` |
| `alias` | `null` | model name in the API. Without `hf`, the default is the file name without `.gguf`. |
| `contextLength` | 32768 | context size in tokens |
| `cacheTypeK`, `cacheTypeV` | `q4_0` | KV cache quantization |
| `flashAttn` | `auto` | `on`, `off` or `auto` |
| `gpuLayers` | `null` | `null` distributes the layers across VRAM automatically |
| `modelDraft`, `gpuLayersDraft`, `specType` | `null` | speculative decoding |
| `mmproj` | `null` | projector GGUF for image recognition |
| `host`, `port` | `127.0.0.1`, 8080 | listen address |
| `openFirewall` | `true` | opens the port |
| `extraSettings` | `{ }` | additional `llama-server` arguments |

The service runs with `DynamicUser`. The module therefore bind-mounts paths under `/home/` read-only into `/var/lib/llama-cpp`.

### searxng

| Option | Default | Meaning |
| --- | --- | --- |
| `domain` | `search.stahl.sh` | search domain |
| `nginx.enable` | `true` | reverse proxy |
| `redlib.enable` | `true` | start Redlib and rewrite Reddit links |
| `redlib.domain` | `reddit.stahl.sh` | Redlib domain |
| `aiAnswers.enable` | `false` | include the AI Answers plugin |
| `aiAnswers.provider` | `ollama` | `openrouter`, `openai`, `ollama`, `localai`, `lmstudio`, `gemini`, `azure` or `huggingface` |
| `aiAnswers.model`, `aiAnswers.url` | `null` | set as `LLM_MODEL` and `LLM_URL` |

## NixOS: system (`system.*`)

| Module | Host | Purpose | Other options (default) |
| --- | --- | --- | --- |
| `fonts` | B | fonts and emoji | `emoji` (`false`), `fonts` (`[]`) |
| `fwupd` | B | firmware updates | – |
| `gnupg` | B | GnuPG agent with `pinentry-qt`, without SSH support | – |
| `gstreamer` | B | GStreamer with plugins | – |
| `nix-gc` | all (on by default) | weekly garbage collection; during builds collects once free space drops below `minFree` | `olderThan` (`14d`), `minFree` (`5` GiB), `maxFree` (`10` GiB) |
| `nix-ld` | B | run foreign, dynamically linked programs | – |
| `secureboot` | B | boots via Lanzaboote and signs bootloader, kernel and initrd for Secure Boot; replaces systemd-boot | `pkiBundle` (`/var/lib/sbctl`) |
| `sops` | B, L | sops-nix | `secretsDir` (`secrets/`), `ageKeyFile` (`~philipp/.config/sops/age/keys.txt`) |
| `tmpfs` | B, L, D | `/tmp` as tmpfs with 50 % of RAM | – |

The `tmpfs` module lives in the directory `modules/nixos/system/tmp`.

The keys for `secureboot` must be created with `sbctl create-keys` before the first rebuild, otherwise installing the bootloader fails.

## NixOS: command line (`cli.*`)

| Module | Host | Purpose | Other options (default) |
| --- | --- | --- | --- |
| `eza` | B, D | installs eza | – |
| `kubernetes` | B | installs `kubectl` and `talosctl` with their client configurations from sops, sets `KUBECONFIG` and `TALOSCONFIG` | `user` (`philipp`), `kubeconfigFile`, `talosconfigFile` |
| `neovim` | all | Neovim via nvf | – |
| `nh` | B, D | `nh` with automatic cleanup (`--keep-since 4d --keep 3`) | – |

The files under `/run/secrets` are read-only. Commands like `kubectl config use-context` therefore need an explicit path to a writable file.

### Neovim

The base sets the leader key to `Space`, relative line numbers, 2-space indentation and the system clipboard. The submodules add:

| Submodule | Content |
| --- | --- |
| `cmp` | completion with nvim-cmp |
| `git` | gitsigns, keybindings under `<leader>h` |
| `lsp` | LSP, format on save, Treesitter and the languages Bash, Fish, Go, JSON, Markdown, Nix (nixfmt), Python (ruff), Rust, TOML, YAML |
| `lualine` | status line |
| `neo-tree` | file tree, toggle with `<leader>e` |
| `rainbow-delimiters` | colored brackets |
| `surround` | mini.surround |
| `telescope` | fuzzy finder |
| `theme` | Tokyo Night in the `night` variant |
| `which-key` | keybinding help |

## NixOS: desktop, hardware, network, games

| Option | Host | Purpose | Other options (default) |
| --- | --- | --- | --- |
| `desktop.plasma` | B | Plasma 6, SDDM with autologin, NetworkManager, KDE Connect | `extraExcludePackages` (`[]`), `remoteDesktop.*` (see below) |
| `hardware.apple` | B | usbmuxd and libimobiledevice for iOS devices | – |
| `hardware.audio` | B | PipeWire with null sink and loopback for the Scarlett 2i2 | `extra-packages` (`[]`) |
| `networking.wireguard` | B | WireGuard support | – |
| `games.steam` | B | Steam, Proton GE, Gamescope, GameMode, MangoHud | – |

Options of `desktop.plasma.remoteDesktop`:

| Option | Default |
| --- | --- |
| `enable` | `false` |
| `port` | 3389 |
| `openFirewall` | `true` |
| `monitor` | 0 |
| `disableH264` | `true`, for compatibility with Windows RDP |
| `usePlasmaProtocol` | `true` |

## Home Manager: command line (`cli.*`)

| Module | Host | Purpose | Other options (default) |
| --- | --- | --- | --- |
| `fish` | B | Fish, plugins, zoxide, eza, deploy-rs and deploy aliases | – |
| `git` | B | Git with LFS and OpenPGP signing | `signingKey` (`0F21E3C3`), `signByDefault` (`true`) |
| `home-manager` | B | Home Manager program | – |
| `lazygit` | B | lazygit | – |
| `neovim` | – | `EDITOR`, aliases `vimdiff` and `less`. Neovim itself is only added if the system has not enabled nvf. | – |

Name and email for Git come from `user.name` and `user.email`. The Fish aliases `nix-aquarius`, `nix-blarm` and `nix-dns` call deploy-rs. `cd` is an alias for `z`.

## Home Manager: applications (`apps.*`)

| Module | Host | Purpose | Other options |
| --- | --- | --- | --- |
| `chatterino` | B | Twitch chat | – |
| `discord` | B | Discord | – |
| `hermes-agent` | B | AI agent, see below | `extraPackages`, `service.enable`, `service.gateway`, `service.secretName` |
| `kitty` | – | terminal with Tokyo Night, currently replaced by `kwi` | `settings`, `font`, `plasma.enable` (shortcut `Meta+Return`) |
| `kwi` | B | KDE terminal based on libghostty-vt, see below | `settings`, `font`, `plasma.enable` (shortcut `Meta+Return`) |
| `libreoffice` | B | LibreOffice | – |
| `librewolf` | B | browser, see below | `extraConfig`, `userChrome`, `settings`, `extensions.packages`, `search` |
| `mpv` | B | mpv and Haruna | – |
| `obs` | B | OBS with plugins | – |
| `signal-desktop` | B | Signal | – |
| `spotify` | B | Spotify | – |
| `thunderbird` | B | Thunderbird | – |
| `zed-editor` | B | Zed, see below | – |

**hermes-agent:** With `service.enable`, `~/.hermes` is owned by Nix. `hermes config set` then no longer writes, and `config.yaml` is merged on every activation. `service.gateway` requires `service.enable`. The only provider is Cortecs; the API key comes from the `hermes-env` secret provided by the NixOS module of the same name. Its `secretName` must match the one here.

**kwi:** The package comes from `pkgs.awesome-flake.kwi`. `settings` and `font` are written to `kwiterminalrc` through plasma-manager, so they only apply with plasma-manager active. The file stays writable, but the next activation overwrites changes made in the settings dialog for the keys set here. The Tokyo Night color scheme is installed as `TokyoNight.colorscheme` under `~/.local/share/kwi/color-schemes/stock` and is referred to in `ColorScheme` as `konsole:TokyoNight.colorscheme`.

**librewolf:** The default search is SearXNG at `search.stahl.sh`. The extensions come from `firefox-addons` and are Bitwarden, Redirector, Return YouTube Dislike, SponsorBlock, uBlock Origin and 7TV. Markdown Viewer is packaged locally because it is missing there. Password saving is off. The extension list is fixed to `x86_64-linux`.

**zed-editor:** The local llama.cpp and Cortecs are configured, the default is Cortecs with `glm-5.3-flash`. Vim mode is on. The agent settings `allow_unsandboxed` and `always_allow_tool_actions` are active: the agent runs tool actions without asking and may run terminal commands outside the sandbox.

## Home Manager: desktop and games

| Option | Host | Purpose |
| --- | --- | --- |
| `desktop.cursor` | B | cursor theme Rosé Pine, size 32 |
| `desktop.hotkeys` | B | close windows with `Meta+Shift+Q` |
| `desktop.panel` | B | Plasma panel at the top of screens 1 and 3 |
| `desktop.spectacle` | B | region screenshot with `Meta+Shift+S` |
| `games.runelite` | B | RuneLite and Bolt Launcher |
