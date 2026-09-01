{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.fonts;
in
{
  options.${namespace}.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    emoji = mkBoolOpt false "Whether or not to enable emojis.";
    fonts = mkOpt (listOf package) [ ] "Custom font packages to install.";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      LOG_ICONS = "true";
    };

    environment.systemPackages = with pkgs; [ font-manager ];

    fonts = {
      fontconfig = mkIf cfg.emoji {
        enable = true;
        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <alias>
              <family>emoji</family>
              <prefer>
                <family>Twitter Color Emoji</family>
                <family>Noto Color Emoji</family>
              </prefer>
            </alias>
            <alias binding="weak">
              <family>monospace</family>
              <append_last>
                <family>Twitter Color Emoji</family>
                <family>Noto Color Emoji</family>
              </append_last>
            </alias>
            <alias binding="weak">
              <family>sans-serif</family>
              <append_last>
                <family>Twitter Color Emoji</family>
                <family>Noto Color Emoji</family>
              </append_last>
            </alias>
            <alias binding="weak">
              <family>serif</family>
              <append_last>
                <family>Twitter Color Emoji</family>
                <family>Noto Color Emoji</family>
              </append_last>
            </alias>
          </fontconfig>
        '';
        defaultFonts = {
          emoji = [
            "Twitter Color Emoji"
            "Noto Color Emoji"
          ];
          monospace = [ "FreeMono" ];
          sansSerif = [ "FreeSans" ];
          serif = [ "FreeSerif" ];
        };
      };

      packages =
        with pkgs;
        [
          twemoji-color-font
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          nerd-fonts.hack
        ]
        ++ cfg.fonts;
    };
  };

}
