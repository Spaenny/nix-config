# NixOS Configuration

This repository contains the NixOS configuration for my system. NixOS is a Linux distribution that relies on the Nix package manager and the Nix expression language to declare and manage system configurations.

## Structure

The repository is structured as follows:

```
.
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

This configuration uses `deploy-rs` for deployment. To deploy the configuration to a specific host, use the following command:

```bash
deploy <hostname>
```

Replace `<hostname>` with the actual hostname of your machine defined in the `flake.nix`.

For example, if you have a host defined as `aquarius` in your `flake.nix`, you would run:

```bash
deploy aquarius
```

### Building the Configuration

To build the configuration without deploying it:

```bash
nix build '.#<hostname>' -L
```

Replace `<hostname>` with the actual hostname of your machine defined in the `flake.nix`.

### Entering the Configuration's Environment

To enter the environment of the configuration:

```bash
nix develop '.#<hostname>'
```

Replace `<hostname>` with the actual hostname of your machine defined in the `flake.nix`.

### Checking the Configuration

To check the configuration for errors:

```bash
nix flake check
```

## Contributing

Contributions are welcome. Please follow the existing structure and ensure all changes are tested before submitting.

## License

No specific license is applied to this configuration. You are free to use and modify it as needed.
