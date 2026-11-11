# Secrets

Secrets are stored encrypted with [sops](https://github.com/getsops/sops) and age in the `secrets/` directory. [sops-nix](https://github.com/Mic92/sops-nix) decrypts them to `/run/secrets` when a host is activated. The Nix store therefore only contains the encrypted files.

This documentation deliberately contains no secret contents. While writing it, only the file names and the key names from the Nix code were read.

## Recipients

`.sops.yaml` defines who can decrypt a file. The first matching rule applies:

| Files | Recipients |
| --- | --- |
| `secrets/bodenheizung-*.{env,yaml,key}` | `primary` and `bodenheizung` |
| all other `secrets/*.{env,yaml,key}` | `primary` |

Other file extensions match no rule.

## Decryption on the hosts

The `system.sops` module picks the identity through the `ageKeyFile` option:

| Value | Identity | Used by |
| --- | --- | --- |
| default | `~philipp/.config/sops/age/keys.txt` | `blarm` |
| `null` | SSH host key `/etc/ssh/ssh_host_ed25519_key` | `bodenheizung` |

A host can only read secrets for which its identity is a recipient. `blarm` therefore needs the private `primary` key at that path.

`bodenheizung` uses the host key because sops-nix installs the secrets early during activation. At that point during boot, the separate `/home` partition is not mounted yet, so a key stored there would be missing and all of the host's secrets would fail.

## Files

| File | Used by |
| --- | --- |
| `blarm-acme.env` | `services.acme` |
| `blarm-ente-server.yaml` | `services.ente-server` |
| `blarm-kanidm.yaml` | `services.kanidm` and the OAuth2 clients of Forgejo and Grafana |
| `blarm-linkwarden.env` | `services.linkwarden` |
| `blarm-monitoring.yaml` | `services.monitoring` (Grafana, Prometheus) |
| `blarm-pve-exporter.yaml` | `services.monitoring` (Proxmox exporter) |
| `blarm-restic.yaml` | `services.restic` |
| `blarm-searxng.env` | `services.searxng` |
| `bodenheizung-hermes.env` | `services.hermes-agent` |
| `bodenheizung-kubeconfig.yaml` | `cli.kubernetes` |
| `bodenheizung-netbird.key` | `services.netbird` |
| `bodenheizung-talosconfig.yaml` | `cli.kubernetes` |

## Editing secrets

This requires a matching private key:

```bash
sops secrets/blarm-restic.yaml          # edit
sops updatekeys secrets/<file>          # update recipients after changing .sops.yaml
```

Afterwards the affected host has to be redeployed. Units with `restartUnits` restart automatically when the secret changes.

## Using secrets in Nix code

The path to the secrets directory always comes from `system.sops.secretsDir`. The module enables sops itself:

```nix
let
  sopsCfg = config.${namespace}.system.sops;
in
{
  ${namespace}.system.sops = enabled;

  # Single value from a YAML file
  sops.secrets.restic_password = mkSopsSecret sopsCfg.secretsDir "blarm-restic.yaml" {
    format = "yaml";
    key = "restic/password";
  };

  # Whole dotenv file
  sops.secrets.linkwarden = mkSopsDotenvSecret sopsCfg.secretsDir "blarm-linkwarden.env";
}
```

The repository uses these patterns:

| Pattern | Example | Note |
| --- | --- | --- |
| single value | `services.restic` | `format = "yaml"` and `key` |
| dotenv | `services.linkwarden` | for `environmentFile` |
| whole file | `cli.kubernetes` | `key = ""` installs the whole decrypted file |
| binary file | `services.netbird` | `format = "binary"` |
| template | `services.ente-server` | `sops.templates` inserts secrets into a file via `config.sops.placeholder` |
| file reference | `services.monitoring` | Grafana reads the value via `$__file{...}` |

Principles:

- Never write secret values directly into Nix expressions, otherwise they end up readable in the Nix store. Always pass the path, i.e. `config.sops.secrets.<name>.path`.
- Use `owner`, `group` and `mode` to give access only to the service that needs the secret. Without these, the file is owned by `root`.
- Use `restartUnits` to make sure the service picks up a changed secret.
