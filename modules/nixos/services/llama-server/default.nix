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
  cfg = config.${namespace}.services.llama-server;

  accelerationPackages = {
    rocm = pkgs.llama-cpp-rocm;
    vulkan = pkgs.llama-cpp-vulkan;
    cuda = pkgs.llama-cpp-cuda;
    cpu = pkgs.llama-cpp;
  };

  mountDir = "/var/lib/llama-cpp";

  # Paths under /home are unreachable for the DynamicUser unit (`ProtectHome`
  # plus a non-traversable home directory). Bind them read-only into the unit
  # below the state directory; the manager mounts them as root, so neither the
  # unit's dynamic uid nor the home permissions matter.
  homeMounts =
    filter (p: hasPrefix "/home/" p) (
      (optional (cfg.hf == null) cfg.model)
      ++ (optional (cfg.mmproj != null) cfg.mmproj)
      ++ (optional (cfg.modelDraft != null) cfg.modelDraft)
    );

  mapServicePath =
    p: if hasPrefix "/home/" p then "${mountDir}/${baseNameOf p}" else p;
in
{
  options.${namespace}.services.llama-server = with types; {
    enable = mkBoolOpt false "llama.cpp server for local large language models.";

    acceleration = mkOption {
      description = "Hardware acceleration backend for inference.";
      type = enum [
        "rocm"
        "vulkan"
        "cuda"
        "cpu"
      ];
      default = "rocm";
    };

    model = mkOption {
      description = "Absolute path to the GGUF model file to serve.";
      type = str;
      default = "/home/philipp/.llama/mtp-Qwen3.8-27B-Q4_0.gguf";
      example = "/data/ssd/models/Qwen3.8-27B-UD-Q4_K_M.gguf";
    };

    hf = mkOption {
      description = ''
        Hugging Face model spec (`<user>/<model>[:quant]`) instead of a local
        path. The model (and its mmproj, if available) is downloaded into the
        server cache on startup.
      '';
      type = nullOr str;
      default = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M";
      example = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M";
    };

    modelDraft = mkOption {
      description = "Path to a draft GGUF for speculative decoding.";
      type = nullOr str;
      default = null;
    };

    gpuLayersDraft = mkOption {
      description = "Number of draft model layers to offload to the GPU.";
      type = nullOr int;
      default = null;
    };

    specType = mkOption {
      description = "Type of speculative decoding to use. Required to activate the draft model (e.g. `draft-mtp`).";
      type = nullOr str;
      default = null;
    };

    mmproj = mkOption {
      description = "Absolute path to a multimodal projector GGUF for vision support.";
      type = nullOr str;
      default = null;
    };

    alias = mkOption {
      description = "Name under which the model is exposed via the API. Defaults to the model file name without `.gguf` suffix.";
      type = nullOr str;
      default = null;
    };

    contextLength = mkOption {
      description = "Context window size in tokens.";
      type = int;
      default = 32768;
    };

    cacheTypeK = mkOption {
      description = "KV cache quantization type for keys. Requires flash attention.";
      type = str;
      default = "q4_0";
    };

    cacheTypeV = mkOption {
      description = "KV cache quantization type for values. Requires flash attention.";
      type = str;
      default = "q4_0";
    };

    flashAttn = mkOption {
      description = "Flash attention mode. Required for quantized KV caches.";
      type = enum [
        "on"
        "off"
        "auto"
      ];
      default = "auto";
    };

    gpuLayers = mkOption {
      description = ''
        Number of model layers to offload to the GPU. If null (default),
        llama-server fits them automatically into the available VRAM.
      '';
      type = nullOr int;
      default = null;
    };

    host = mkOption {
      description = "IP address on which the server should listen on.";
      type = str;
      default = "127.0.0.1";
    };

    port = mkOption {
      description = "Port on which the server should listen on.";
      type = port;
      default = 8080;
    };

    openFirewall = mkBoolOpt true "Open the firewall for the server port.";

    extraSettings = mkOption {
      description = "Additional `llama-server` arguments, keyed by their long option name.";
      type = attrs;
      default = { };
      example = literalExpression ''
        {
          spec-type = "draft-mtp";
          spec-draft-n-max = 2;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.model != "" || cfg.hf != null;
        message = "${namespace}.services.llama-server requires either `model` (GGUF path) or `hf` (Hugging Face spec).";
      }
    ];

    services.llama-cpp = {
      enable = true;

      package = accelerationPackages.${cfg.acceleration};

      inherit (cfg) openFirewall;

      settings = {
        inherit (cfg) host port;

        ctx-size = cfg.contextLength;
        cache-type-k = cfg.cacheTypeK;
        cache-type-v = cfg.cacheTypeV;
        flash-attn = cfg.flashAttn;
        # Use the chat template embedded in the GGUF (thinking, tool calls).
        jinja = true;
      }
      // optionalAttrs (cfg.gpuLayers != null) { n-gpu-layers = cfg.gpuLayers; }
      // (if cfg.hf != null then { hf-repo = cfg.hf; } else { model = mapServicePath cfg.model; })
      // optionalAttrs (cfg.alias != null) { alias = cfg.alias; }
      // optionalAttrs (cfg.hf == null && cfg.alias == null) {
        alias = removeSuffix ".gguf" (baseNameOf cfg.model);
      }
      // optionalAttrs (cfg.mmproj != null) { mmproj = mapServicePath cfg.mmproj; }
      // optionalAttrs (cfg.modelDraft != null) { model-draft = mapServicePath cfg.modelDraft; }
      // optionalAttrs (cfg.gpuLayersDraft != null) {
        gpu-layers-draft = cfg.gpuLayersDraft;
      }
      // optionalAttrs (cfg.specType != null) { spec-type = cfg.specType; }
      // cfg.extraSettings;
    };

    # The upstream unit runs with DynamicUser; the render group is required to
    # access the GPU devices.
    systemd.services.llama-cpp.serviceConfig = {
      SupplementaryGroups = [
        "render"
        "video"
      ];
    }
    // optionalAttrs (homeMounts != [ ]) {
      BindReadOnlyPaths = map (p: "${p}:${mountDir}/${baseNameOf p}") homeMounts;
    };
  };
}
