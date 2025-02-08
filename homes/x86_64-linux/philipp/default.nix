{
  ...
}:
{
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
      chatterino.enable = true;
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
