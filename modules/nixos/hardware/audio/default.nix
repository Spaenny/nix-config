{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.hardware.audio;
in
{
  options.${namespace}.hardware.audio = with types; {
    enable = mkBoolOpt false "Whether or not to enable audio support.";
    extra-packages = mkOpt (listOf package) [ ] "Additional packages to install.";
  };

  config = mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    services.pulseaudio.enable = false;

    environment.systemPackages =
      with pkgs;
      [
        pulsemixer
        pavucontrol
      ]
      ++ cfg.extra-packages;

    services.pipewire.extraConfig.pipewire = {
      "90-nullsink" = {
        "context.object" = [
          {
            factory = "adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "Null Sink";
              "media.class" = "Audio/Sink";
              "audio.position" = "[ FL FR ]";
              "monitor.channel-volumes" = "true";
              "monitor.passthrough" = "true";
              "adapter.auto-port-config" = {
                "mode" = "dsp";
                "monitor" = "true";
                "position" = "preserve";
              };
            };
          }
        ];
      };
      "90-loopback" = {
        "context.modules" = [
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Scarlett 2i2 Loopback";
              "capture.props" = {
                "node.name" = "Scarlett_2i2_Loopback";
                "media.class" = "Audio/Sink";
                "audio.position" = "[ FL FR ]";
              };
              "playback.props" = {
                "node.name" = "playback.Scarlett_2i2_Loopback";
                "audio.position" = "[ AUX0 AUX1 ]";
                "target.object" = "alsa_output.usb-Focusrite_Scarlett_2i2_USB-00.pro-output-0";
                "stream.dont-reconnect" = "true";
                "node.dont-reconnect" = "false";
                "node.passive" = "true";
              };
            };
          }
        ];
      };
    };
  };

}
