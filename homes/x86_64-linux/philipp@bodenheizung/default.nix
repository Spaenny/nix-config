{
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  ${namespace} = {
    cli = {
      fish = enabled;
      git = enabled;
      home-manager = enabled;
      lazygit = enabled;
    };

    apps = {
      librewolf = enabled;
      libreoffice = enabled;
      thunderbird = enabled;
      chatterino = enabled;
      mpv = enabled;
      cinny = disabled; # Currently insecure because of libsoup
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
