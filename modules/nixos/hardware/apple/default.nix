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
  cfg = config.${namespace}.hardware.apple;
in
{
  options.${namespace}.hardware.apple = {
    enable = mkBoolOpt false "Whether or not to enable support for Apple (iOS) devices.";
  };

  config = mkIf cfg.enable {
    # usbmuxd daemon: recognises Apple devices over USB and multiplexes
    # connections to them for all libimobiledevice tools.
    services.usbmuxd.enable = true;

    environment.systemPackages = with pkgs; [
      # Pairing/troubleshooting CLI tools (idevicepair, ideviceinfo, ...).
      libimobiledevice
      # Install/manage apps on paired devices.
      ideviceinstaller
    ];
  };
}
