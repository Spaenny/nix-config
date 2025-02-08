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
  cfg = config.${namespace}.desktop.plasma;

  excludePackages = with pkgs.kdePackages; [
    konsole
    elisa
    krdp
  ];

  default-attrs = mapAttrs (key: mkDefault);
  nested-default-attrs = mapAttrs (key: default-attrs);
in
{
  options.${namespace}.desktop.plasma = with types; {
    enable = mkBoolOpt false "Whether or not to use Plasma as the desktop environment.";
    extraExcludePackages = mkOpt (listOf package) [ ] "Extra packages to exclude";
  };

  config = mkIf cfg.enable {
    services.desktopManager.plasma6.enable = true;
    services.displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        settings = {
          Autologin = {
            Session = "plasma.desktop";
            User = "philipp";
          };
          Theme = {
            EnableAvatars = true;
          };
        };
      };
    };

    environment.plasma6.excludePackages =
      with pkgs.kdePackages;
      [ ] ++ excludePackages ++ cfg.extraExcludePackages;

    networking.networkmanager.enable = true;

    environment.systemPackages = with pkgs; [
      pinentry-qt
      kdiskmark
      networkmanager
      kdePackages.networkmanager-qt
    ];
  };

}
