{
  mkHomeConfiguration,
  mkNixosConfiguration,
  ...
}:
let
  homeRoot = ../homes/x86_64-linux;
in
{
  flake = {
    nixosConfigurations = {
      aquarius = mkNixosConfiguration "aarch64-linux" [ ../systems/aarch64-linux/aquarius ];
      blarm = mkNixosConfiguration "x86_64-linux" [ ../systems/x86_64-linux/blarm ];
      bodenheizung = mkNixosConfiguration "x86_64-linux" [
        ../systems/x86_64-linux/bodenheizung
        { home-manager.users.philipp = import (homeRoot + "/philipp@bodenheizung"); }
      ];
      dns = mkNixosConfiguration "x86_64-linux" [ ../systems/x86_64-linux/dns ];
    };

    homeConfigurations = {
      "philipp@bodenheizung" = mkHomeConfiguration "x86_64-linux" [
        (homeRoot + "/philipp@bodenheizung")
      ];
    };
  };
}
