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
  cfg = config.${namespace}.services.lact;

  # LACT expects the fan curve as a map of temperature (°C) to fan speed as a
  # fraction of the maximum RPM, e.g. "1200:65" with maxRpm = 3000 -> 65: 0.4.
  lactCurve = map (
    pair:
    let
      parts = splitString ":" pair;
      rpm = toInt (head parts);
      temp = toInt (head (tail parts));
      fraction = builtins.floor ((rpm * 1.0 / cfg.maxRpm) * 1000) / 1000.0;
      speed = min 1.0 (max 0.0 fraction);
      # Nix's toString renders 1.0 as "1"; LACT's YAML deserializer wants a
      # float there, so make sure a decimal point is present.
      speedStr =
        let
          s = toString speed;
        in
        if hasInfix "." s || hasInfix "e" s || hasInfix "E" s then s else "${s}.0";
    in
    {
      temperature = temp;
      speed = speedStr;
    }
  ) (splitString "," cfg.fanCurve);

  # Rendered by hand instead of via services.lact.settings (pkgs.formats.yaml):
  # that generator quotes numeric map keys ('65': 0.4), which LACT's
  # deserializer rejects with `invalid type: string, expected i32`, crashing
  # lactd on startup. Plain integer keys in hand-rolled YAML parse fine.
  #
  # The `version` and `daemon` sections are required fields of LACT's Config
  # struct when a config file exists (only gpus/profiles have serde defaults).
  # version 7 is the current schema version; admin_group keeps CLI/GUI socket
  # access for wheel users, matching the daemon's built-in default.
  configLines = [
    "version: 7"
    "daemon:"
    "  log_level: info"
    "  admin_group: wheel"
    "gpus:"
    "  ${cfg.gpuId}:"
    "    fan_control_enabled: true"
    "    fan_control_settings:"
    "      mode: curve"
    "      temperature_key: edge"
    "      interval_ms: 500"
    "      static_speed: 0.5"
    "      curve:"
  ]
  ++ map (point: "        ${toString point.temperature}: ${point.speed}") lactCurve
  ++ optionals (cfg.voltageOffset != null) [
    "    performance_level: manual"
    "    voltage_offset: ${toString cfg.voltageOffset}"
  ];

  lactConfigYaml = pkgs.writeText "lact-config.yaml" (
    concatStringsSep "\n" configLines + "\n"
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

    voltageOffset = mkOption {
      type = nullOr int;
      default = null;
      description = ''
        Undervolt the GPU core (VDDGFX) by this many millivolts, e.g. `-100`
        for a 100 mV undervolt. Applicable to RDNA and newer AMD GPUs; the
        value must be within the card's hardware offset range (RX 9070:
        -200 to 0 mV, shown as `OD_VDDGFX_OFFSET` by LACT).

        Setting this automatically switches the performance level to `manual`,
        which the amdgpu driver requires for writing voltage offsets. Clock
        control stays adaptive on RDNA3+.
      '';
    };
  };

  config = mkIf cfg.enable {
    # settings stay empty on purpose: the upstream module renders them with
    # pkgs.formats.yaml, whose quoted numeric map keys crash lactd (see
    # configLines above). Packages and the lactd unit still come from upstream.
    services.lact.enable = true;

    environment.etc."lact/config.yaml".source = lactConfigYaml;

    systemd.services.lactd.restartTriggers = [ lactConfigYaml ];
  };
}
