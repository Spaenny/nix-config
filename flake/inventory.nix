let
  homeRoot = ../homes/x86_64-linux;
  mkHost = system: modules: { inherit system modules; };
  mkDeployNode = configuration: hostname: attrs: { inherit configuration hostname; } // attrs;
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
    aquarius = mkDeployNode "aquarius" "aquarius" { interactiveSudo = false; };
    blarm = mkDeployNode "blarm" "blarm" { interactiveSudo = false; };
    dns-1 = mkDeployNode "dns" "dns-1" { interactiveSudo = false; };
    dns-2 = mkDeployNode "dns" "dns-2" { interactiveSudo = false; };
  };
}
