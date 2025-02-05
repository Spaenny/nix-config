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

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
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

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager { 
          home-manager.sharedModules = [ inputs.plasma-manager.homeManagerModules.plasma-manager ]; 
          home-manager.backupFileExtension = "bk-hm";
        }
        nvf.nixosModules.default
      ];

      outputs-builder = channels: { formatter = channels.nixpkgs.nixfmt-rfc-style; };
    };
}
