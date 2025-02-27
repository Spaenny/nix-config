{
  lib, ...
}:
{
  home.activation.removeBrowserBackups = lib.hm.dag.entryAfter ["checkLinkTargets"] ''  
    if [ -d "/home/philipp/.librewolf/philipp" ]; then
      rm -f /home/philipp/.librewolf/philipp/search.json.mozlz4.backup
    fi 
  '';
  awesome-flake = {
    cli-apps = {
      fish.enable = true;
      home-manager.enable = true;
      lazygit.enable = true;
    };

    tools = {
      git.enable = true;
    };

    apps = {
      librewolf.enable = true;
      thunderbird.enable = true;
      chatterino.enable = true;
      mpv.enable = true;
      kitty = {
        enable = true;
        plasma.enable = true;
      };
    };

    games = {
      runelite.enable = true;
    };

    desktop = {
      hotkeys.enable = true;
      panel.enable = true;
    };
  };
}
