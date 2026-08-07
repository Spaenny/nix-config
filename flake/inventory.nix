let
  homeRoot = ../homes/x86_64-linux;
  mkHost = system: modules: { inherit system modules; };
  mkDeployNode = configuration: hostname: { inherit configuration hostname; };
in
{
  flakeRoot = "/home/philipp/Projects/nix-config";

  nixosConfigurations = {
    aquarius = mkHost "aarch64-linux" [ ../systems/aarch64-linux/aquarius ];
    blarm = mkHost "x86_64-linux" [ ../systems/x86_64-linux/blarm ];
    bodenheizung = mkHost "x86_64-linux" [
      ../systems/x86_64-linux/bodenheizung
      { home-manager.users.philipp = import (homeRoot + "/philipp@bodenheizung"); }
    ];
    dns = mkHost "x86_64-linux" [ ../systems/x86_64-linux/dns ];
  };

  homeConfigurations = {
    "philipp@bodenheizung" = mkHost "x86_64-linux" [ (homeRoot + "/philipp@bodenheizung") ];
  };

  deployNodes = {
    aquarius = mkDeployNode "aquarius" "aquarius";
    blarm = mkDeployNode "blarm" "blarm";
    dns-1 = mkDeployNode "dns" "dns-1";
    dns-2 = mkDeployNode "dns" "dns-2";
  };
}
