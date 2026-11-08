{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.cli.kubernetes;
  sopsCfg = config.${namespace}.system.sops;

  # key = "" installs the whole decrypted file instead of a single value.
  mkConfigSecret =
    file:
    mkSopsSecret sopsCfg.secretsDir file {
      format = "yaml";
      key = "";
      owner = cfg.user;
      mode = "0400";
    };
in
{
  options.${namespace}.cli.kubernetes = with types; {
    enable = mkBoolOpt false "Whether to install the kubectl and talosctl client configs from sops.";

    user = mkOpt str "philipp" "User that may read the decrypted client configs.";

    kubeconfigFile =
      mkOpt str "bodenheizung-kubeconfig.yaml"
        "Encrypted sops file below the secrets directory that holds the kubeconfig.";

    talosconfigFile =
      mkOpt str "bodenheizung-talosconfig.yaml"
        "Encrypted sops file below the secrets directory that holds the talosconfig.";
  };

  config = mkIf cfg.enable {
    ${namespace}.system.sops = enabled;

    sops.secrets = {
      kubeconfig = mkConfigSecret cfg.kubeconfigFile;
      talosconfig = mkConfigSecret cfg.talosconfigFile;
    };

    # The files below /run/secrets are read-only, so commands that write to the
    # config (kubectl config use-context, talosctl config merge) need an
    # explicit --kubeconfig or --talosconfig pointing at a writable file.
    environment.sessionVariables = {
      KUBECONFIG = config.sops.secrets.kubeconfig.path;
      TALOSCONFIG = config.sops.secrets.talosconfig.path;
    };
  };
}
