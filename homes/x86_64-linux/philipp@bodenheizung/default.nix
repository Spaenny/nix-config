{
  lib,
  pkgs,
  namespace,
  ...
}:
with lib.${namespace};
{
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.rose-pine-cursor;
    name = "BreezeX-RosePine-Linux";
    size = 32;
  };

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
      spotify = enabled;
      obs = enabled;
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
    };
  };
}
