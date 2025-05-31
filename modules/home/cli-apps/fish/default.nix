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
        nix-dns = "nixos-rebuild switch --flake ${flakeRoot}/.#dns --target-host dns-1 --use-remote-sudo && nixos-rebuild switch --flake ${flakeRoot}/.#dns --target-host dns-2 --use-remote-sudo";
        nix-blarm = "nixos-rebuild switch --flake ${flakeRoot}/.#blarm --target-host blarm --use-remote-sudo";
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
