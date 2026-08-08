{ lib, ... }:

with lib;
rec {
  ## Create a NixOS module option.
  ##
  ## ```nix
  ## lib.mkOpt nixpkgs.lib.types.str "My default" "Description of my option."
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };

  ## Create a NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkOpt' nixpkgs.lib.types.str "My default"
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt' = type: default: mkOpt type default null;

  ## Create a boolean NixOS module option.
  ##
  ## ```nix
  ## lib.mkBoolOpt true "Description of my option."
  ## ```
  ##
  #@ Type -> Any -> String
  mkBoolOpt = mkOpt types.bool;

  ## Create a boolean NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkBoolOpt true
  ## ```
  ##
  #@ Type -> Any -> String
  mkBoolOpt' = mkOpt' types.bool;

  ## Create an enable option that defaults to true.
  #@ String -> Option
  mkEnabledOption = description: mkEnableOption description // { default = true; };

  ## Create a common TLS nginx proxy virtual host.
  #@ Attrs -> Attrs
  mkNginxProxyHost =
    {
      acmeHost ? "stahl.sh",
      proxyPass,
      location ? { },
      ...
    }@attrs:
    removeAttrs attrs [
      "acmeHost"
      "proxyPass"
      "location"
    ]
    // {
      forceSSL = true;
      useACMEHost = acmeHost;
      locations."/" = {
        inherit proxyPass;
      }
      // location;
    };

  ## Create a common TLS nginx static-file virtual host.
  #@ Attrs -> Attrs
  mkNginxStaticHost =
    {
      acmeHost ? "stahl.sh",
      root,
      location ? { },
      ...
    }@attrs:
    removeAttrs attrs [
      "acmeHost"
      "root"
      "location"
    ]
    // {
      forceSSL = true;
      useACMEHost = acmeHost;
      locations."/" = {
        inherit root;
      }
      // location;
    };

  ## Create a sops-nix secret backed by a file below the configured secrets
  ## directory.
  ##
  ## ```nix
  ## sops.secrets.example = mkSopsSecret cfg.secretsDir "example.yaml" {
  ##   key = "example/password";
  ## };
  ## ```
  ##
  #@ Path -> String -> Attrs -> Attrs
  mkSopsSecret =
    secretsDir: file: attrs:
    attrs // { sopsFile = secretsDir + "/${file}"; };

  ## Create a dotenv sops-nix secret from the configured secrets directory.
  #@ Path -> String -> Attrs
  mkSopsDotenvSecret = secretsDir: file: mkSopsSecret secretsDir file { format = "dotenv"; };

  enabled = {
    ## Quickly enable an option.
    ##
    ## ```nix
    ## services.nginx = enabled;
    ## ```
    ##
    #@ true
    enable = true;
  };

  disabled = {
    ## Quickly disable an option.
    ##
    ## ```nix
    ## services.nginx = enabled;
    ## ```
    ##
    #@ false
    enable = false;
  };
}
