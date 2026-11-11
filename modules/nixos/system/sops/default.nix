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
    ageKeyFile = mkOpt (nullOr str) "${config.users.users.philipp.home}/.config/sops/age/keys.txt" ''
      Age identity file used by sops-nix. Set it to null to decrypt with the
      SSH host key instead: secrets are installed during early activation,
      before a separate /home is mounted, so a key below /home is missing at
      boot and every secret of the host fails with it.
    '';
  };

  config = mkIf cfg.enable {
    sops.age = {
      keyFile = cfg.ageKeyFile;
      sshKeyPaths = mkIf (cfg.ageKeyFile == null) [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    environment.systemPackages = with pkgs; [
      age
      sops
    ];
  };

}
