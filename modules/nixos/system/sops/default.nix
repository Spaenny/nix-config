{
  config,
  inputs,
  lib,
  namespace,
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
  };

  config = mkIf cfg.enable {
    sops.age.keyFile = "/home/philipp/.config/sops/age/keys.txt";
  };

}
