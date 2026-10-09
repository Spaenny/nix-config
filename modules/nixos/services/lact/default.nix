{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.lact;

  # LACT expects the fan curve as a map of temperature (°C) to fan speed as a
  # fraction of the maximum RPM, e.g. "1200:65" with maxRpm = 3000 -> '65': 0.4.
  lactCurve = listToAttrs (
    map (
      pair:
      let
        parts = splitString ":" pair;
        rpm = toInt (head parts);
        temp = head (tail parts);
        fraction = builtins.floor ((rpm * 1.0 / cfg.maxRpm) * 1000) / 1000.0;
      in
      {
        name = temp;
        value = min 1.0 (max 0.0 fraction);
      }
    ) (splitString "," cfg.fanCurve)
  );
in
{
  options.${namespace}.services.lact = with types; {
    enable = mkEnableOption "GPU fan curve control via the LACT daemon.";

    fanCurve = mkOption {
      type = str;
      default = "1000:70,2000:85,3000:100";
      description = ''
        Comma-separated list of `<rpm>:<temperature>` pairs, e.g.
        `1200:65,2000:85,3000:100`: run the fan at 1200 RPM once the GPU
        reaches 65 °C, at 2000 RPM from 85 °C and at maximum speed from
        100 °C. RPM values are normalized against {option}`maxRpm`.
      '';
    };

    maxRpm = mkOption {
      type = int;
      default = 3000;
      description = ''
        Maximum fan speed in RPM that the {option}`fanCurve` RPM values are
        normalized against, since LACT expects curve speeds as 0.0–1.0
        fractions of the maximum.
      '';
    };

    gpuId = mkOption {
      type = str;
      description = ''
        LACT identifier of the GPU to control, in the format
        `vendor:device-subvendor:subdevice-pciaddress`, e.g.
        `1002:7550-1025:187A-0000:28:00.0`, as shown by `lact cli list`.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Thin wrapper around the upstream nixpkgs module: it ships the packaged
    # `lactd.service` unit and renders settings as /etc/lact/config.yaml.
    services.lact = {
      enable = true;
      settings.gpus.${cfg.gpuId} = {
        fan_control_enabled = true;
        fan_control_settings = {
          mode = "curve";
          temperature_key = "edge";
          interval_ms = 500;
          static_speed = 0.5;
          curve = lactCurve;
        };
      };
    };
  };
}
