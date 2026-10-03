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
  cfg = config.${namespace}.services.ollama;

  accelerationPackages = {
    rocm = pkgs.ollama-rocm;
    vulkan = pkgs.ollama-vulkan;
    cuda = pkgs.ollama-cuda;
    cpu = pkgs.ollama-cpu;
  };
in
{
  options.${namespace}.services.ollama = with types; {
    enable = mkBoolOpt false "Ollama server for local large language models.";

    models = mkOption {
      description = "Models to pull automatically once the server has started.";
      type = listOf str;
      default = [ ];
    };

    syncModels = mkBoolOpt false "Remove installed models that are not declared in `models`.";

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

    keepAlive = mkOption {
      description = "How long a loaded model stays in VRAM/RAM between requests.";
      type = str;
      default = "30m";
    };
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;

      package = accelerationPackages.${cfg.acceleration};

      loadModels = cfg.models;
      syncModels = cfg.syncModels;

      environmentVariables = {
        OLLAMA_KEEP_ALIVE = cfg.keepAlive;
        OLLAMA_KV_CACHE_TYPE = "q4_0";
        OLLAMA_CONTEXT_LENGTH = "32768";
      };
    };
  };
}
