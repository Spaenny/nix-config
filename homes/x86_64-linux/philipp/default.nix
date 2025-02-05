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
      kitty = {
        enable = true;
        plasma.enable = true;
      };
    };
    desktop = {
      hotkeys.enable = true;
    };
  };
}
