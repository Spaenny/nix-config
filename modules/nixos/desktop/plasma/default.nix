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
    elisa
  ];
in
{
  options.${namespace}.desktop.plasma = with types; {
    enable = mkBoolOpt false "Whether or not to use Plasma as the desktop environment.";
    extraExcludePackages = mkOpt (listOf package) [ ] "Extra packages to exclude";

    remoteDesktop = {
      enable = mkBoolOpt false "Whether to enable KDE Remote Desktop via KRdp.";
      disableH264 = mkBoolOpt true "Whether to disable H.264 encoding for KRdp to improve Windows RDP compatibility.";
      monitor =
        mkOpt (nullOr int) 0
          "The monitor index to stream via KRdp. Set to null to let KRdp choose.";
      openFirewall = mkBoolOpt true "Whether to open the RDP port in the firewall.";
      port = mkOpt port 3389 "RDP port for KDE Remote Desktop.";
      usePlasmaProtocol = mkBoolOpt true "Whether to use KRdp's Plasma screencasting protocol instead of the XDG desktop portal.";
    };
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
      excludePackages
      ++ optional (!cfg.remoteDesktop.enable) pkgs.kdePackages.krdp
      ++ cfg.extraExcludePackages;

    programs.kdeconnect.enable = true;

    environment.sessionVariables = mkIf (cfg.remoteDesktop.enable && cfg.remoteDesktop.disableH264) {
      KRDP_DISABLE_H264 = "1";
    };

    systemd.user.services."app-org.kde.krdpserver" = mkIf cfg.remoteDesktop.enable {
      description = "KRDP Server";
      environment = optionalAttrs cfg.remoteDesktop.disableH264 {
        KRDP_DISABLE_H264 = "1";
      };
      after = [
        "plasma-core.target"
        "plasma-xdg-desktop-portal-kde.service"
      ];
      wantedBy = [ "plasma-workspace.target" ];

      serviceConfig = {
        Type = "exec";
        ExecStart = concatStringsSep " " (
          [
            "${pkgs.kdePackages.krdp}/bin/krdpserver"
            "--port"
            (toString cfg.remoteDesktop.port)
          ]
          ++ optional (cfg.remoteDesktop.monitor != null) "--monitor ${toString cfg.remoteDesktop.monitor}"
          ++ optional cfg.remoteDesktop.usePlasmaProtocol "--plasma"
        );
        Restart = "on-abnormal";
      };
    };

    networking.firewall = mkIf (cfg.remoteDesktop.enable && cfg.remoteDesktop.openFirewall) {
      allowedTCPPorts = [ cfg.remoteDesktop.port ];
    };

    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };

    environment.systemPackages = with pkgs; [
      pinentry-qt
      kdiskmark
      networkmanager
      kdePackages.networkmanager-qt
      kdePackages.kio
      kdePackages.kio-fuse
      kdePackages.kio-extras
      #kdePackages.wallpaper-engine-plugin Currently crashes plasma
    ];
  };

}
