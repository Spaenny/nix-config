# NixOS Configuration Documentation

This repository describes four NixOS configurations as a Nix flake: a desktop, a self-hosting server and the DNS servers of the home network. The desktop also has a Home Manager configuration.

As of 2026-11-06. The details on active modules, ports and virtual hosts were checked with `nix eval` against the working tree at that time, including changes that had not been committed yet.

## Contents

| Document | Topic |
| --- | --- |
| [Architecture](architecture.md) | Flake layout, module system, helper functions, overlays and packages |
| [Hosts](hosts.md) | The machines and what is active on them |
| [Services on blarm](services.md) | Domains, ports, data, single sign-on, monitoring and backups |
| [Module reference](modules.md) | All NixOS and Home Manager modules with their options |
| [Secrets](secrets.md) | Working with sops-nix and age |
| [Operations](operations.md) | Deploying, updating, CI and common changes |
| [Open issues](open-issues.md) | Oddities noticed while writing the documentation |

## Hosts at a glance

| Host | Architecture | Role | Deployment |
| --- | --- | --- | --- |
| `bodenheizung` | x86_64 | Desktop with KDE Plasma, gaming and local LLMs | locally with `nh os switch` |
| `blarm` | x86_64, Proxmox LXC | Self-hosting server | `deploy .#blarm` |
| `dns` (`dns-1`, `dns-2`) | x86_64, Proxmox LXC | Technitium DNS server, one configuration for two instances | `deploy --targets .#dns-1 .#dns-2` |
| `aquarius` | aarch64, SD card image | Technitium DNS server | `deploy .#aquarius` |

## Quick start

```bash
nix flake check                     # check the configuration (also runs in CI)
nix fmt -- <file>                   # format a Nix file with nixfmt
nh os switch                        # switch bodenheizung locally
deploy .#blarm                      # deploy a server
```

New files must be known to Git before Nix can see them: a flake in a Git repository only evaluates tracked files. Details are under [Operations](operations.md#new-files-and-git).
