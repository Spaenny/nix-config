{
  lib,
  config,
  inputs,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.cli-apps.fish;
  flakeRoot = "/home/philipp/Documents/nixos-config";
in
{
  options.${namespace}.cli-apps.fish = {
    enable = mkEnableOption "fish";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default ];

    programs.fish = {
      enable = true;
      shellAliases = {
        nix-aquarius = "deploy ${flakeRoot}#aquarius";
        nix-blarm = "deploy ${flakeRoot}#blarm";
        nix-dns = "deploy --targets ${flakeRoot}#dns-1 ${flakeRoot}#dns-2";
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
