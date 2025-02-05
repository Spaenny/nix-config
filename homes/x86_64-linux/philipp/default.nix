{
  ...
}:
{
  awesome-flake = {
    cli-apps = {
      fish.enable = true;
      home-manager.enable = true;
    };

    tools = {
      git.enable = true;
    };

    apps = {
      librewolf.enable = true;
      kitty.enable = true;
    };
  };
}
