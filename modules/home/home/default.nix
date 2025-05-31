{
  lib,
  osConfig ? { },
  ...
}:
{
  home = {
    username = "philipp";
    homeDirectory = "/home/philipp";
    stateVersion = lib.mkDefault (osConfig.system.stateVersion or "24.11");
  };

}
