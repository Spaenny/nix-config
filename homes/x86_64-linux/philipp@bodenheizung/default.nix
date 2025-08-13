{
  lib,
  pkgs,
  namespace,
  ...
}:
with lib.${namespace};
{
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
      libreoffice = enabled;
      thunderbird = enabled;
      chatterino = enabled;
      mpv = enabled;
      cinny = enabled;
      spotify = enabled;
      obs = enabled;
      discord = enabled;
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
      spectacle = enabled;
      cursor = enabled;
    };
  };
}
