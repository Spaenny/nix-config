{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.cli-apps.fish;
  flakeRoot = "/home/philipp/Documents/nix-config";
in
{
  options.${namespace}.cli-apps.fish = {
    enable = mkEnableOption "fish";
  };

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
      shellAliases = {
        cd = "z";
        ls = "exa --icons";
        l = "exa";
      };
      plugins = [
        {
          name = "fzf";
          src = pkgs.fishPlugins.fzf.src;
        }
        {
          name = "hydro";
          src = pkgs.fishPlugins.hydro.src;
        }
        {
          name = "sponge";
          src = pkgs.fishPlugins.sponge.src;
        }
        {
          name = "z";
          src = pkgs.fishPlugins.z.src;
        }
      ];
    };

    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    programs.eza = {
      enable = true;
      enableFishIntegration = true;
    };
  };

}
