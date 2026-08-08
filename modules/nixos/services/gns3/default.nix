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
    services.gns3-server = {
      enable = true;
      ubridge.enable = true;
      dynamips.enable = true;
    };

    environment.systemPackages = with pkgs; [
      dynamips
      gns3-gui
    ];
  };

}
