{
  channels,
  inputs,
  ...
}:

final: prev: {
  awesome-flake = (prev.awesome-flake or { }) // {
    cinny = prev.cinny-unwrapped.overrideAttrs (_old: rec {
      pname = "cinny-unwrapped";
      version = "65475050d76d6e8da8c3402528215b1425e8ed4e";

      src = final.fetchFromGitHub {
        owner = "GigiaJ";
        repo = "cinny";
        rev = version;
        hash = "sha256-kJZDc53mcJrGIw3Dl4ANq+1O5O2p0tcO2btQGNGRg4A=";
      };

      npmDepsHash = "sha256-GkD+CrblXBv7yPVrTBVIGkz7Wu5llWzlluNq7rmm3CE=";
      npmDeps = final.fetchNpmDeps {
        inherit src;
        name = "${pname}-${version}-npm-deps";
        hash = npmDepsHash;
      };
    });
  };
}
