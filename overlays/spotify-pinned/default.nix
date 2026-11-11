{ inputs }:
_final: prev:

let
  pinnedPkgs = import inputs.nixpkgs-spotify {
    inherit (prev.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  # The snap revision nixpkgs fetches is gone from snapcraft.io, so a fresh
  # build fails. Take Spotify from the previous nixpkgs, whose build is still
  # in the local store, until nixpkgs moves to a downloadable revision.
  inherit (pinnedPkgs) spotify;
}
