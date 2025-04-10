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
  cfg = config.${namespace}.system.gstreamer;
in
{
  options.${namespace}.system.gstreamer = with types; {
    enable = mkBoolOpt false "Whether or not to enable gstreamer support.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Video/Audio data composition framework tools like "gst-inspect", "gst-launch" ...
      gst_all_1.gstreamer
      # Common plugins like "filesrc" to combine within e.g. gst-launch
      gst_all_1.gst-plugins-base
      # Specialized plugins separated by quality
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      # Plugins to reuse ffmpeg to play almost every video format
      gst_all_1.gst-libav
      # Support the Video Audio (Hardware) Acceleration API
      gst_all_1.gst-vaapi
    ];

    environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
      lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0"
        (
          with pkgs.gst_all_1;
          [
            gstreamer
            gst-plugins-base
            gst-plugins-good
            gst-plugins-bad
            gst-plugins-ugly
            gst-libav
            gst-vaapi
          ]
        );
  };

}
