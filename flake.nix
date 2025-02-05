{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf.url = "github:notashelf/nvf";
  };

  outputs =
    inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        # Configure Snowfall Lib, all of these settings are optional.
        snowfall = {
          root = ./.;
          namespace = "awesome-flake";
          meta = {
            name = "awesome-flake";
            title = "Awesome Flake";
          };
        };
      };
    in
    lib.mkFlake {
      channels-config.allowUnfree = true;
      home-manager.backupFileExtension = "hm-bk";
      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        nvf.nixosModules.default
      ];

      outputs-builder = channels: { formatter = channels.nixpkgs.nixfmt-rfc-style; };
    }
    // {
      self = inputs.self;
    };
}
