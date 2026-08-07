{
  lib,
  inventory,
  mkHomeConfiguration,
  mkNixosConfiguration,
  ...
}:
{
  flake = {
    nixosConfigurations = lib.mapAttrs (
      _name: host: mkNixosConfiguration host.system host.modules
    ) inventory.nixosConfigurations;

    homeConfigurations = lib.mapAttrs (
      _name: home: mkHomeConfiguration home.system home.modules
    ) inventory.homeConfigurations;
  };
}
