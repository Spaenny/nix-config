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
  cfg = config.${namespace}.apps.zed-editor;
in
{
  options.${namespace}.apps.zed-editor = with types; {
    enable = mkBoolOpt false "Whether or not to enable zed-editor.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      zed-editor
    ];
  };

}
