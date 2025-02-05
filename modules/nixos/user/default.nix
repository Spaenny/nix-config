{
  options,
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.user;
in
{
  programs.fish = {
    enable = true;
  };

  users.users.philipp = {
    isNormalUser = true;
    shell = pkgs.fish;
  };
}
