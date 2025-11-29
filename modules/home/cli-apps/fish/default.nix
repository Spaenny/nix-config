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
        nix-dns = "nh os switch -H dns --target-host dns-1 && nh os switch -H dns --target-host dns-2";
        nix-blarm = "nh os switch -H blarm --target-host blarm";
        nix-aquarius = "nh os switch -H aquarius --target-host aquarius";
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
