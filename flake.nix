{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf.url = "github:notashelf/nvf";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    twitch-hls-client.url = "github:2bc4/twitch-hls-client";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      deploy-rs,
      home-manager,
      nvf,
      plasma-manager,
      ...
    }:
    let
      namespace = "awesome-flake";
      lib = nixpkgs.lib.extend (
        _final: _prev: {
          ${namespace} = import ./lib/module/default.nix { lib = nixpkgs.lib; };
        }
      );
      homeLib = lib.extend (
        _final: _prev: {
          hm = home-manager.lib.hm;
        }
      );

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      importTree =
        root:
        let
          scan =
            prefix: dir:
            lib.concatMapAttrs (
              name: type:
              let
                path = dir + "/${name}";
                moduleName = if prefix == "" then name else "${prefix}/${name}";
              in
              if type == "directory" then
                (lib.optionalAttrs (builtins.pathExists (path + "/default.nix")) {
                  ${moduleName} = import path;
                })
                // scan moduleName path
              else
                { }
            ) (builtins.readDir dir);
        in
        scan "" root;

      packageSet = pkgs: {
        codeberg-themes = pkgs.callPackage ./packages/codeberg-themes { };
        ente-web-auth = pkgs.callPackage ./packages/ente-web-auth { };
        linkwarden = pkgs.callPackage ./packages/linkwarden { };
        redlib = pkgs.callPackage ./packages/redlib { };
      };

      packageOverlay = final: prev: {
        ${namespace} = (prev.${namespace} or { }) // packageSet final;
      };
      packageOverlayFor = name: final: prev: {
        ${namespace} = (prev.${namespace} or { }) // {
          ${name} = (packageSet final).${name};
        };
      };

      overlays = {
        cinny = import ./overlays/cinny;
        redlib-fixed = import ./overlays/redlib-fixed;
        technitium-dns-server = import ./overlays/technitium-dns-server;
        packages = packageOverlay;
        "package/codeberg-themes" = packageOverlayFor "codeberg-themes";
        "package/ente-web-auth" = packageOverlayFor "ente-web-auth";
        "package/linkwarden" = packageOverlayFor "linkwarden";
        "package/redlib" = packageOverlayFor "redlib";
        default =
          final: prev:
          lib.composeManyExtensions [
            packageOverlay
            overlays.cinny
            overlays.redlib-fixed
            overlays.technitium-dns-server
          ] final prev;
      };

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlays.default ];
        };

      nixosModules = importTree ./modules/nixos;
      homeManagerModules = importTree ./modules/home;
      commonSpecialArgs = {
        inherit inputs namespace;
        lib = lib;
      };
      commonHomeSpecialArgs = commonSpecialArgs // {
        lib = homeLib;
      };

      commonHomeModules = builtins.attrValues homeManagerModules ++ [
        plasma-manager.homeModules.plasma-manager
      ];

      commonNixosModules = builtins.attrValues nixosModules ++ [
        home-manager.nixosModules.home-manager
        nvf.nixosModules.default
        {
          nixpkgs.overlays = [ overlays.default ];
          nixpkgs.config.allowUnfree = true;

          home-manager.useGlobalPkgs = true;
          home-manager.backupFileExtension = "bk-hm";
          home-manager.sharedModules = commonHomeModules;
          home-manager.extraSpecialArgs = commonHomeSpecialArgs;
        }
      ];

      mkNixosConfiguration =
        system: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs;
          modules = commonNixosModules ++ modules;
        };

      mkHomeConfiguration =
        system: modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs = commonHomeSpecialArgs;
          modules = commonHomeModules ++ modules;
        };

      nixosConfigurations = {
        aquarius = mkNixosConfiguration "aarch64-linux" [ ./systems/aarch64-linux/aquarius ];
        blarm = mkNixosConfiguration "x86_64-linux" [ ./systems/x86_64-linux/blarm ];
        bodenheizung = mkNixosConfiguration "x86_64-linux" [
          ./systems/x86_64-linux/bodenheizung
          { home-manager.users.philipp = import (./homes/x86_64-linux + "/philipp@bodenheizung"); }
        ];
        dns = mkNixosConfiguration "x86_64-linux" [ ./systems/x86_64-linux/dns ];
      };

      deployNode = nixosConfiguration: hostname: {
        inherit hostname;
        sshUser = "philipp";
        profiles.system = {
          user = "root";
          path =
            deploy-rs.lib.${nixosConfiguration.pkgs.stdenv.hostPlatform.system}.activate.nixos
              nixosConfiguration;
        };
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = supportedSystems;

      perSystem =
        { system, ... }:
        let
          pkgs = pkgsFor system;
        in
        {
          _module.args.pkgs = pkgs;

          packages = packageSet pkgs;
          formatter = pkgs.nixfmt;
          checks = deploy-rs.lib.${system}.deployChecks self.deploy;
        };

      flake = {
        inherit nixosConfigurations overlays;

        nixosModules = nixosModules;
        homeManagerModules = homeManagerModules;
        homeModules = homeManagerModules;

        homeConfigurations = {
          "philipp@bodenheizung" = mkHomeConfiguration "x86_64-linux" [
            (./homes/x86_64-linux + "/philipp@bodenheizung")
          ];
        };

        deploy.nodes = {
          aquarius = deployNode nixosConfigurations.aquarius "aquarius";
          blarm = deployNode nixosConfigurations.blarm "blarm";
          dns-1 = deployNode nixosConfigurations.dns "dns-1";
          dns-2 = deployNode nixosConfigurations.dns "dns-2";
        };
      };
    };
}
