{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  options.flakeRoot = mkOption {
    type = types.str;
    description = "Path to the flake root directory.";
  };

  config.flakeRoot = "${config.users.users.philipp.home}/Documents/nix-config";
}
