{
  lib,
  pkgs,
  namespace,
  ...
}:
with lib.${namespace};
{
  home.activation.disableKrdpAutostart = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file krdpserverrc --group General --key Autostart false
  '';

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
      signal-desktop = enabled;
      zed-editor = enabled;
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
