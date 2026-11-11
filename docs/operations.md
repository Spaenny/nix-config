# Operations

## Prerequisites

- Nix with the `nix-command` and `flakes` features
- SSH access as `philipp` to the targets; the names `aquarius`, `blarm`, `dns-1` and `dns-2` must resolve
- for secrets, a matching private age key, see [Secrets](secrets.md)

`deploy` is installed on `bodenheizung` through the Home Manager module `cli.fish`.

## New files and Git

A flake in a Git repository only sees files that Git knows about. Otherwise a new file causes errors like `path ... does not exist`, even though it exists on disk. A commit is not required, this is enough:

```bash
git add -N <file>      # only mark the file as intended to add
```

The same applies to new encrypted files under `secrets/`.

## Checking and building

```bash
nix flake check                                                       # evaluation and deploy-rs checks
nix build .#nixosConfigurations.blarm.config.system.build.toplevel -L # build a host
nix build .#ente-server -L                                            # build a custom package
nix fmt -- <file>                                                     # format a file
nix fmt -- --check <file>                                             # only check formatting
```

`aquarius` can be built on `bodenheizung` through `binfmt` emulation.

## Deploying

### bodenheizung (local)

```bash
nh os switch           # NH_FLAKE points to the repository
nh os test             # activate without creating a boot entry
```

Alternatively without `nh`:

```bash
sudo nixos-rebuild switch --flake .#bodenheizung
```

Some changes only take effect after a reboot, such as kernel parameters and `hardware.amdgpu.overdrive`.

### Servers with deploy-rs

| Target | Command | Fish alias |
| --- | --- | --- |
| `blarm` | `deploy .#blarm` | `nix-blarm` |
| `dns-1` and `dns-2` | `deploy --targets .#dns-1 .#dns-2` | `nix-dns` |
| `aquarius` | `deploy .#aquarius` | `nix-aquarius` |

The aliases use the absolute path of the repository and therefore work from any directory.

Useful `deploy` flags:

| Flag | Effect |
| --- | --- |
| `--dry-activate` | only simulate activation |
| `--boot` | activate on the next reboot |
| `-s`, `--skip-checks` | skip flake checks |
| `--magic-rollback <bool>` | control automatic rollback on connection loss |
| `--auto-rollback <bool>` | control rollback on failed activation |

Activation runs as `root`. On the servers, `services.ssh.passwordlessDeploy` allows passwordless `sudo` for this, limited to deploy-rs's activation programs in the Nix store and deleting its canary files. The inventory sets `interactiveSudo = false` for this.

## Updating

```bash
nix flake update                # all inputs
nix flake update nixpkgs        # a single input
```

Afterwards build or check, then switch `bodenheizung` first and the servers after that. The change to `flake.lock` is usually committed as `chore(flake): update locked inputs`.

Custom packages and overlays are pinned and are not updated through `flake.lock`. Version, revision and hashes have to be adjusted by hand. This applies to `packages/`, `overlays/redlib-fixed`, the plugin in `services.searxng` and `librewolf/markdown-viewer.nix`.

## CI

`.forgejo/workflows/main.yml` runs on every push and pull request. The workflow installs Nix and runs `nix flake check`, which includes the `formatting` check: it fails if any tracked `.nix` file is not formatted with nixfmt. It needs a Forgejo runner with the label `ubuntu-latest-thingy`. The runner itself is not part of this repository. CI does not deploy anything.

## Git

- Commit messages follow Conventional Commits, for example `feat(monitoring): …`, `fix(dns): …`, `chore(flake): …`.
- `origin` pushes to three remotes at once, and `forgejo` points to the self-hosted instance.
- Commits are signed with OpenPGP by default.

## Common changes

### Enabling an existing module

Add it to `systems/<arch>/<host>/default.nix` and deploy:

```nix
${namespace}.services.paperless = enabled;
```

### New module

1. Create `modules/nixos/<area>/<name>/default.nix` following the [pattern](architecture.md#module-structure).
2. Run `git add -N`. No list needs to be updated.
3. For web services, use `mkNginxProxyHost` and enable `services.acme`.
4. Enable the module on the host.

Extra files like `kanidm.nix` must be pulled in via `imports`. A subdirectory with its own `default.nix`, on the other hand, is loaded automatically.

### New OAuth2 client in Kanidm

Examples are `services/kanidm/proxmox.nix` for external applications and `services/forgejo/kanidm.nix` for services from this repository.

1. Add the secret `kanidm/oauth2/<name>/basic-secret` to `secrets/blarm-kanidm.yaml`.
2. Write a file with `sops.secrets` and `services.kanidm.provision.systems.oauth2.<name>`, plus a group.
3. Add the file to the `imports` list of the responsible module.

### New host

1. Create `systems/<arch>/<name>/default.nix`. For real hardware, add `hardware-configuration.nix`.
2. Add the host to `flake/inventory.nix` under `nixosConfigurations`.
3. For deployments, add an entry to `deployNodes` and set `services.ssh.passwordlessDeploy` on the host.
4. If the host needs its own secrets: derive its key with `ssh-to-age`, add a rule to `.sops.yaml` and run `sops updatekeys`.

### New package

1. Create `packages/<name>/default.nix`.
2. Add the package to `packageSet` in `flake/default.nix`. Packages are not discovered automatically.

### New overlay

1. Create `overlays/<name>/default.nix`.
2. In `flake/default.nix`, add it both to the `overlays` attribute set and to the list in `default`.

## Checking and restoring backups

On `blarm`, NixOS creates the wrapper `restic-borgbase`, which already knows the repository and password:

```bash
sudo restic-borgbase snapshots
sudo restic-borgbase restore latest --target /data/restore --include /data/paperless
sudo systemctl start restic-backups-borgbase.service   # start a backup right now
```

`/tmp` is not suitable as a target, because on `blarm` it is a tmpfs with 50 % of RAM.

For a restore, the sources are:

- **PostgreSQL** (Forgejo, Ente): dumps from `/var/backup/postgresql`
- **Kanidm:** online backups from `/var/lib/kanidm/backups`
- **Everything else:** directories under `/data` and `/var/lib`

Stop the affected service before restoring. This procedure is only described here and was not tested while writing the documentation.

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| Nix does not find a new file | It is not tracked by Git, so run `git add -N <file>` |
| `nix flake check` fails in `check-formatting` | Run `nix fmt -- <file>` on the files nixfmt lists |
| Secrets are missing after boot | The identity is not available. For hosts with a separate `/home` partition, set `sops.ageKeyFile = null` and add the host as a recipient. |
| `sops` cannot open a file | The current key lacks permission, or the file needs `sops updatekeys` |
| `deploy` asks for a password or `sudo` fails | `services.ssh.passwordlessDeploy` is not active on the target yet. The option has to be enabled once some other way, for example with `nixos-rebuild` on the target. |
| The service does not pick up a new secret | Set `restartUnits` on the secret or restart the service by hand |
| `lactd` does not start | LACT rejects the generated YAML. That is why the module writes it by hand instead of through `services.lact.settings`. The configuration is at `/etc/lact/config.yaml`. |
| llama-server runs out of memory | Lower `contextLength` or check the cache quantization, leave `gpuLayers` at `null` |
| NetBird does not log in | Check the `netbird-login` unit. It retries failed logins every 15 seconds. |
| Forgejo shows no Kanidm login | Check the `forgejo-kanidm-auth-source` unit |
