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

  programs.fish.interactiveShellInit = ''
    set --global fish_color_autosuggestion brblack
    set --global fish_color_cancel -r
    set --global fish_color_command blue
    set --global fish_color_comment red
    set --global fish_color_cwd green
    set --global fish_color_cwd_root red
    set --global fish_color_end green
    set --global fish_color_error brred
    set --global fish_color_escape brcyan
    set --global fish_color_history_current --bold
    set --global fish_color_host normal
    set --global fish_color_host_remote yellow
    set --global fish_color_normal normal
    set --global fish_color_operator brcyan
    set --global fish_color_param cyan
    set --global fish_color_quote yellow
    set --global fish_color_redirection cyan --bold
    set --global fish_color_search_match white --background=brblack
    set --global fish_color_selection white --bold --background=brblack
    set --global fish_color_status red
    set --global fish_color_user brgreen
    set --global fish_color_valid_path --underline
    set --global fish_pager_color_completion normal
    set --global fish_pager_color_description yellow -i
    set --global fish_pager_color_prefix normal --bold --underline
    set --global fish_pager_color_progress brwhite --background=cyan
    set --global fish_pager_color_selected_background -r
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
      spotify = enabled;
      obs = enabled;
      discord = enabled;
      signal-desktop = enabled;
      zed-editor = enabled;
      hermes-agent = {
        enable = true;
        service = {
          enable = true;
          gateway = true;
        };
      };
      kitty = disabled;
      kwi = {
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
