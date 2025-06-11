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
    "browser.startup.homepage" = "https://search.stahl.sh";
    "browser.startup.page" = 3;
    "privacy.resistFingerprinting" = false;
    "privacy.fingerprintingProtection" = true;
    "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme,-JSDateTimeUTC";
    "privacy.clearOnShutdown.history" = false;
    "signon.rememberSignons" = true;
    "signon.storeWhenAutocompleteOff" = true;
    "sidebar.verticalTabs" = true;
    "general.useragent.compatMode.firefox" = true;
    "browser.search.suggest.enabled" = true;
    "browser.urlbar.suggest.searches" = true;
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
    force = true; # We need this, else the build fails
    privateDefault = "SearXNG";
    default = "SearXNG";
    engines = {
      "SearXNG" = {
        urls = [
          { template = "https://search.stahl.sh/search?q={searchTerms}"; }
          {
            template = "https://search.stahl.sh/autocompleter?q={searchTerms}";
            type = "application/x-suggestions+json";
          }
        ];
        icon = "https://search.stahl.sh/static/themes/simple/img/favicon.png";
        definedAliases = [ "@s" ];
      };

      "My Nixos Packages" = {
        urls = [ { template = "https://mynixos.com/search?q={searchTerms}"; } ];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = [ "@mnp" ];
      };

      "NixOS Wiki" = {
        urls = [ { template = "https://wiki.nixos.org/index.php?search={searchTerms}"; } ];
        icon = "https://wiki.nixos.org/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [ "@nw" ];
      };

      "NixOS Packages" = {
        urls = [ { template = "https://search.nixos.org/packages?query={searchTerms}"; } ];
        icon = "https://wiki.nixos.org/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [ "@np" ];
      };

      "NixOS Options" = {
        urls = [ { template = "https://search.nixos.org/options?query={searchTerms}"; } ];
        icon = "https://wiki.nixos.org/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [ "@no" ];
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
