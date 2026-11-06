# NixOS Configuration

This repository contains the NixOS configuration for my system. NixOS is a Linux distribution that relies on the Nix package manager and the Nix expression language to declare and manage system configurations.

## Structure

The repository is structured as follows:

```
.
├── docs                # Documentation (German)
├── flake               # Flake outputs and host inventory
├── flake.nix           # Flakes configuration
├── flake.lock          # Lock file for flakes
├── homes               # Home-manager configurations
├── modules             # Reusable NixOS modules
│   ├── home            # Home-manager configurations
│   └── nixos           # NixOS modules
│       ├── desktop     # Desktop environment configurations
│       ├── hardware    # Hardware-specific configurations
│       ├── networking  # Networking configurations
│       ├── programs    # Program configurations
│       ├── services    # Service configurations
│       ├── system      # System configurations
│       └── user        # User configurations
├── overlays            # Nixpkgs overlays
├── packages            # Custom packages
├── systems             # System configurations
└── ...                 # Other configuration files
```

## Prerequisites

- Nix package manager installed
- Flakes enabled (add `experimental-features = nix-command flakes` to `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`)
- Basic familiarity with Nix and NixOS

## Usage

### Deploying the Configuration

The servers are deployed with `deploy-rs`. To deploy a node defined under `deployNodes` in `flake/inventory.nix`, run the following from the repository root:

```bash
deploy '.#<node>'
```

For example, to deploy `aquarius`, or both DNS servers at once:

```bash
deploy '.#aquarius'
deploy --targets '.#dns-1' '.#dns-2'
```

`bodenheizung` is not a deploy node. It is switched locally:

```bash
nh os switch
```

### Building the Configuration

To build a configuration defined under `nixosConfigurations` in `flake/inventory.nix` without deploying it:

```bash
nix build '.#nixosConfigurations.<hostname>.config.system.build.toplevel' -L
```

### Checking the Configuration

To check the configuration for errors:

```bash
nix flake check
```

## Documentation

The full documentation is in [docs/](docs/README.md).

## Contributing

Contributions are welcome. Please follow the existing structure and ensure all changes are tested before submitting.

## License

No specific license is applied to this configuration. You are free to use and modify it as needed.
