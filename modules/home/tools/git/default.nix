{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkEnableOption mkIf;
  inherit (lib.${namespace}) mkOpt enabled;

  cfg = config.${namespace}.tools.git;
  user = config.${namespace}.user;
in
{
  options.${namespace} = {
    tools.git = {
      enable = mkEnableOption "Git";
      signingKey = mkOpt types.str "0F21E3C3" "The key ID to sign commits with.";
      signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
    };
    user = {
      name = mkOpt types.str "Philipp" "The name to configure git with.";
      email = mkOpt types.str "philipp@boehm.sh" "The email to configure git with.";
    };
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs = enabled;
      signing = {
        key = cfg.signingKey;
        inherit (cfg) signByDefault;
      };
      settings = {
        inherit user;
        init = {
          defaultBranch = "main";
        };
        pull = {
          rebase = true;
        };
        push = {
          autoSetupRemote = true;
        };
        core = {
          whitespace = "trailing-space,space-before-tab";
        };
      };
    };
  };
}
