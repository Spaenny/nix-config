{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.gns3;
in
{
  options.${namespace}.services.gns3 = {
    enable = mkBoolOpt false "GNS3";
  };

  config = mkIf cfg.enable {
    services.gns3-server.enable = true;
    services.gns3-server.ubridge.enable = true;
    services.gns3-server.dynamips.enable = true;

    environment.systemPackages = with pkgs; [
      dynamips
      gns3-gui
    ];
  };

}
