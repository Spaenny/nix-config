{
  inputs,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.apps.librewolf;
  defaultSettings = {
    "browser.startup.homepage" = "https://search.monapona.dev";
    "browser.startup.page" = 3;
    "privacy.resistFingerprinting" = false;
    "privacy.fingerprintingProtection" = true;
    "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme,-JSDateTimeUTC";
    "privacy.clearOnShutdown.history" = false;
    "signon.rememberSignons" = true;
    "signon.storeWhenAutocompleteOff" = true;
    "sidebar.verticalTabs" = true;
  };
  defaultExtensions = with inputs.firefox-addons.packages."x86_64-linux"; [
    bitwarden
    redirector
    return-youtube-dislikes
    sponsorblock
    ublock-origin
    seventv
  ];
  defaultSearch = {
    privateDefault = "SearXNG";
    default = "SearXNG";
    engines = {
      "SearXNG" = {
        urls = [ { template = "https://search.monapona.dev/search?q={searchTerms}"; } ];
        iconUpdateURL = "https://search.monapona.dev/static/themes/simple/img/favicon.png";
        definedAliases = [ "@s" ];
      };

      "My Nixos Packages" = {
        urls = [ { template = "https://mynixos.com/search?q={searchTerms}"; } ];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = [ "@np" ];
      };

      "NixOS Wiki" = {
        urls = [ { template = "https://wiki.nixos.org/index.php?search={searchTerms}"; } ];
        iconUpdateURL = "https://wiki.nixos.org/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [ "@nw" ];
      };
    };
  };
in
{
  options.${namespace}.apps.librewolf = with types; {
    enable = mkBoolOpt false "Whether or not to enable Firefox.";
    extraConfig = mkOpt str "" "Extra configuration for the user profile JS file.";
    userChrome = mkOpt str "" "Extra configuration for the user chrome CSS file.";
    settings = mkOpt attrs defaultSettings "Settings to apply to the profile.";
    extensions.packages =
      mkOpt (listOf package) defaultExtensions
        "Extra Librewolf extensions to install.";
    search = mkOpt attrs defaultSearch "Extra search engines to define.";
  };

  config = mkIf cfg.enable {
    programs.librewolf = {
      enable = true;
      package = pkgs.librewolf-wayland;

      profiles."philipp" = {
        inherit (cfg)
          extraConfig
          userChrome
          settings
          extensions
          search
          ;
        id = 0;
        name = "Philipp";
        isDefault = true;
      };

    };
  };

}
