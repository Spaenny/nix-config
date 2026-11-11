# Hosts

All hosts use `nixos-unstable`, `stateVersion` `24.11` and the user `philipp` with Fish as the shell. The time zone is `Europe/Berlin`.

The tables show the effective modules, including those that another module enables automatically.

## bodenheizung

Desktop with KDE Plasma, gaming, virtualization and a local LLM. Files: `systems/x86_64-linux/bodenheizung/`.

| Area | Active modules |
| --- | --- |
| `services` | `btrfs`, `hermes-agent`, `lact`, `llama-server`, `netbird`, `printer`, `ssh` |
| `system` | `fonts`, `fwupd`, `gnupg`, `gstreamer`, `nix-ld`, `secureboot`, `sops`, `tmpfs` |
| `cli` | `eza`, `kubernetes`, `neovim`, `nh` |
| `desktop` / `hardware` | `plasma` with remote desktop / `apple`, `audio` |
| `games` / `networking` | `steam` / `wireguard` |

### Hardware and boot

- AMD CPU and AMD GPU, Zen kernel, zram swap with zstd
- Secure Boot via Lanzaboote with custom sbctl keys plus the Microsoft keys (needed for the GPU's option ROM and for Windows on `sdb`)
- Btrfs on LUKS with the subvolumes `root`, `home`, `nix`, `log` and `persist`. Root unlocks with any of the three YubiKeys via FIDO2, without PIN and without touch; without a key, the password prompt appears after 5 s.
- second encrypted SSD at `/data/ssd`, opened via `/etc/crypttab` with a key file on root (`nofail`, `discard`, 10 s timeout)
- `binfmt` emulation for `aarch64-linux`, so `aquarius` can be built here
- libvirt with swtpm, plus Flatpak and TeamViewer
- `gnumake` as a system package

### GPU and local LLM

- `hardware.amdgpu.overdrive.enable` unlocks the sysfs interface for LACT and only takes effect after a reboot.
- LACT controls the fan curve and lowers the core voltage by 100 mV.
- `llama-server` runs with ROCm and the model `underdog-saluki-27b`, context 98,304 tokens, KV cache `q4_0`, automatic layer offloading. The model is downloaded from Hugging Face at startup. The service is deliberately reachable from outside on port 8080.
- Zed talks to the server at `http://localhost:8080`. The model name in `apps.zed-editor` must match the server's `alias`.

### Network

Open ports according to evaluation:

| Protocol | Ports | Purpose |
| --- | --- | --- |
| TCP | 22 | SSH |
| TCP | 3389 | KRdp (remote desktop) |
| TCP | 8080 | llama-server, listens on `0.0.0.0` |
| TCP | 27036, 27037 | Steam Remote Play |
| TCP and UDP | 1714–1764 | KDE Connect |
| UDP | 5353 | mDNS (Avahi) |
| UDP | 10400, 10401, 27031–27036 | Steam Remote Play |
| UDP | 51820 | NetBird |

NetBird connects to `https://netbird.u0k.de` with a setup key.

### Secrets

`sops.ageKeyFile = null`: the host decrypts with its SSH host key instead of an age key. `/home` is not mounted yet when the secrets are installed. More on this under [Secrets](secrets.md#decryption-on-the-hosts).

### Home Manager

`homes/x86_64-linux/philipp@bodenheizung/default.nix` enables:

| Area | Modules |
| --- | --- |
| `cli` | `fish`, `git`, `home-manager`, `lazygit` |
| `apps` | `chatterino`, `discord`, `hermes-agent` (with service and gateway), `kwi`, `libreoffice`, `librewolf`, `mpv`, `obs`, `signal-desktop`, `spotify`, `thunderbird`, `zed-editor` |
| `games` | `runelite` |
| `desktop` | `cursor`, `hotkeys`, `panel`, `spectacle` |

The configuration turns off KRdp autostart in `krdpserverrc` on every activation.

## blarm

Self-hosting server as a Proxmox LXC container. File: `systems/x86_64-linux/blarm/default.nix`. Its services are described in [Services on blarm](services.md).

| Area | Active modules |
| --- | --- |
| `services` | `acme`, `cinny`, `ente-auth`, `ente-server`, `forgejo`, `kanidm`, `linkwarden`, `monitoring`, `nginx`, `opencloud`, `paperless`, `restic`, `samba`, `searxng`, `ssh`, `syncthing` |
| `system` | `sops`, `tmpfs` |
| `cli` | `neovim` |

Open ports are TCP 22, 80, 139, 443, 445 and 8384 as well as UDP 137 and 138. The configured nameservers are `192.168.5.100`, `192.168.5.200` and their IPv6 counterparts.

Most data lives under `/data`. This directory is not declared as a file system in the repository, so it comes from outside, presumably as a Proxmox mount point.

## dns

One configuration for the two Proxmox LXC containers `dns-1` and `dns-2`. File: `systems/x86_64-linux/dns/default.nix`.

| Area | Active modules |
| --- | --- |
| `services` | `ssh`, `technitium-dns-server` |
| `system` | `tmpfs` |
| `cli` | `eza`, `neovim`, `nh` |

- The host uses no secrets and does not enable sops.
- Open are TCP 22, 53, 80, 443, 853, 5380 and 53443 as well as UDP 53.
- The hostname is not set in Nix, because the same configuration applies to both instances.
- Proxmox generates the systemd-networkd files with `IPv6AcceptRA=false`, which prevents SLAAC. A drop-in under `/etc/systemd/network/net0.network.d/` overrides only this setting. The addresses managed by Proxmox stay untouched.

## aquarius

Technitium DNS server on an aarch64 board that boots from an SD card image. Files: `systems/aarch64-linux/aquarius/`.

| Area | Active modules |
| --- | --- |
| `services` | `ssh`, `technitium-dns-server` |
| `cli` | `neovim` |

- Boots via extlinux instead of GRUB
- Network via systemd-networkd: `end0` via DHCP, `wg*` interfaces stay unmanaged
- SSH without password login and without root login
- same open ports as `dns`
