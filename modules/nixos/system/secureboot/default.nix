{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.secureboot;
in
{
  options.${namespace}.system.secureboot = with types; {
    enable = mkBoolOpt false "Whether or not to boot through Lanzaboote with Secure Boot signing.";

    # The keys must exist before the first rebuild (sbctl create-keys),
    # otherwise installing the bootloader fails.
    pkiBundle = mkOpt str "/var/lib/sbctl" "Directory holding the sbctl Secure Boot keys.";
  };

  config = mkIf cfg.enable {
    # Lanzaboote replaces the systemd-boot module and installs its own signed
    # systemd-boot plus a stub per generation.
    boot.loader.systemd-boot.enable = mkForce false;

    boot.lanzaboote = {
      enable = true;
      inherit (cfg) pkiBundle;
    };

    environment.systemPackages = with pkgs; [ sbctl ];
  };
}
