{
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  home.activation.removeBrowserBackups = lib.hm.dag.entryAfter [ "checkLinkTargets" ] ''
    if [ -d "/home/philipp/.librewolf/philipp" ]; then
      rm -f /home/philipp/.librewolf/philipp/search.json.mozlz4.backup
    fi 
  '';
  awesome-flake = {
    cli-apps = {
      fish = enabled;
      home-manager = enabled;
      lazygit = enabled;
    };

    tools = {
      git = enabled;
    };

    apps = {
      librewolf = enabled;
      thunderbird = enabled;
      chatterino = enabled;
      mpv = enabled;
      cinny = enabled;
      kitty = {
        enable = true;
        plasma = enabled;
      };
    };

    games = {
      runelite = enabled;
    };

    desktop = {
      hotkeys = enabled;
      panel = enabled;
    };
  };
}
