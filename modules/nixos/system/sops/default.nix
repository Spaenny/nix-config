{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.sops;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.${namespace}.system.sops = with types; {
    enable = mkBoolOpt false "Whether or not to enable sops support.";
    secretsDir = mkOpt path ../../../../secrets "Directory containing encrypted sops files.";
    ageKeyFile =
      mkOpt str "${config.users.users.philipp.home}/.config/sops/age/keys.txt"
        "Age identity file used by sops-nix.";
  };

  config = mkIf cfg.enable {
    sops.age.keyFile = cfg.ageKeyFile;

    environment.systemPackages = with pkgs; [
      age
      sops
    ];
  };

}
