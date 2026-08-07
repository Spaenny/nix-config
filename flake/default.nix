{
  inputs,
  ...
}:
let
  namespace = "awesome-flake";
  lib = inputs.nixpkgs.lib.extend (
    _final: _prev: {
      ${namespace} = import ../lib/module/default.nix { lib = inputs.nixpkgs.lib; };
    }
  );
  homeLib = lib.extend (_final: _prev: { hm = inputs.home-manager.lib.hm; });

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
    codeberg-themes = pkgs.callPackage ../packages/codeberg-themes { };
    ente-web-auth = pkgs.callPackage ../packages/ente-web-auth { };
    linkwarden = pkgs.callPackage ../packages/linkwarden { };
    redlib = pkgs.callPackage ../packages/redlib { };
  };

  packageOverlay = final: prev: {
    ${namespace} = (prev.${namespace} or { }) // packageSet final;
  };
  packageOverlayFor = name: final: prev: {
    ${namespace} = (prev.${namespace} or { }) // {
      ${name} = (packageSet final).${name};
    };
  };

  overlays = rec {
    cinny = import ../overlays/cinny;
    redlib-fixed = import ../overlays/redlib-fixed;
    technitium-dns-server = import ../overlays/technitium-dns-server;
    packages = packageOverlay;
    "package/codeberg-themes" = packageOverlayFor "codeberg-themes";
    "package/ente-web-auth" = packageOverlayFor "ente-web-auth";
    "package/linkwarden" = packageOverlayFor "linkwarden";
    "package/redlib" = packageOverlayFor "redlib";
    default =
      final: prev:
      lib.composeManyExtensions [
        packageOverlay
        cinny
        redlib-fixed
        technitium-dns-server
      ] final prev;
  };

  pkgsFor =
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ overlays.default ];
    };

  nixosModules = importTree ../modules/nixos;
  homeManagerModules = importTree ../modules/home;

  commonSpecialArgs = {
    inherit inputs namespace;
    lib = lib;
  };
  commonHomeSpecialArgs = commonSpecialArgs // {
    lib = homeLib;
  };

  commonHomeModules = builtins.attrValues homeManagerModules ++ [
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  commonNixosModules = builtins.attrValues nixosModules ++ [
    inputs.home-manager.nixosModules.home-manager
    inputs.nvf.nixosModules.default
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
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules = commonNixosModules ++ modules;
    };

  mkHomeConfiguration =
    system: modules:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor system;
      extraSpecialArgs = commonHomeSpecialArgs;
      modules = commonHomeModules ++ modules;
    };

  deployNode = nixosConfiguration: hostname: {
    inherit hostname;
    interactiveSudo = true;
    sshUser = "philipp";
    profiles.system = {
      user = "root";
      path =
        inputs.deploy-rs.lib.${nixosConfiguration.pkgs.stdenv.hostPlatform.system}.activate.nixos
          nixosConfiguration;
    };
  };
in
{
  imports = [
    ./deploy.nix
    ./hosts.nix
    ./modules.nix
    ./overlays.nix
    ./packages.nix
  ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  _module.args = {
    inherit
      deployNode
      homeManagerModules
      mkHomeConfiguration
      mkNixosConfiguration
      nixosModules
      overlays
      packageSet
      pkgsFor
      ;
  };
}
