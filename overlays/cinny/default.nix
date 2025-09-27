{
  channels,
  inputs,
  ...
}:

final: prev: {
  awesome-flake = (prev.awesome-flake or { }) // {
    cinny = prev.cinny-unwrapped.overrideAttrs (_old: rec {
      pname = "cinny-unwrapped";
      version = "76ac4e298733e67dbfcd3f0c3a4bae169cd521dd";

      src = final.fetchFromGitHub {
        #owner = "GigiaJ";
        owner = "cinnyapp";
        repo = "cinny";
        rev = version;
        hash = "sha256-tvBaONJwfkCK77aHmWJ/UAAZHq2WIc7geNT2tEFKuZ0=";
      };

      npmDepsHash = "sha256-9faffTlXEI1lMrVrkSyso/tfjs/4W+TVzmiv+bZAv18=";
      npmDeps = final.fetchNpmDeps {
        inherit src;
        name = "${pname}-${version}-npm-deps";
        hash = npmDepsHash;
      };
    });
  };
}
