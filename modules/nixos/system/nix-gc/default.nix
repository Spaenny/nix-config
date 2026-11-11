{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.nix-gc;
  gib = n: n * 1024 * 1024 * 1024;
in
{
  options.${namespace}.system.nix-gc = with types; {
    enable = mkEnabledOption "automatic Nix garbage collection";
    olderThan = mkOpt str "14d" "Delete generations older than this.";
    minFree = mkOpt int 5 "Collect garbage during builds once less than this many GiB are free.";
    maxFree = mkOpt int 10 "Stop that collection once this many GiB are free.";
  };

  # Without this, old generations piled up until blarm's root was full.
  config = mkIf cfg.enable {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than ${cfg.olderThan}";
    };

    nix.settings = {
      min-free = gib cfg.minFree;
      max-free = gib cfg.maxFree;
    };
  };
}
