{
  channels,
  inputs,
  ...
}:

final: prev: {
  awesome-flake = (prev.awesome-flake or { }) // {
    cinny = prev.cinny-unwrapped.overrideAttrs (_old: rec {
      pname = "cinny-unwrapped";
      version = "325144d8b2ca53c32fc6e1eace0603968a5ddc40";

      src = final.fetchFromGitHub {
        owner = "GigiaJ";
        repo = "cinny";
        rev = version;
        hash = "sha256-822P12rzSLzje7KuBF2RB70SPdfCaHZaPV/1Nr4CCnY=";
      };

      npmDepsHash = "sha256-pP7JH/K9QSqyUVg0UFTDzZvRoL5CeP5pudv83eHVoTo=";
      npmDeps = final.fetchNpmDeps {
        inherit src;
        name = "${pname}-${version}-npm-deps";
        hash = npmDepsHash;
      };
    });
  };
}
