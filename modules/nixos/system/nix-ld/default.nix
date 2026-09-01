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
  cfg = config.${namespace}.system.nix-ld;
in
{
  options.${namespace}.system.nix-ld = with types; {
    enable = mkBoolOpt false "Whether or not to enable nix-ld for running dynamically linked generic Linux binaries.";
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        openssl
        curl
        expat
        icu
        nss
        nspr
      ];
    };
  };
}
