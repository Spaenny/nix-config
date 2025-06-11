{
  channels,
  inputs,
  ...
}:

final: prev: {
  awesome-flake = (prev.awesome-flake or { }) // {
    cinny = prev.cinny-unwrapped.overrideAttrs (_old: rec {
      pname = "cinny-unwrapped";
      version = "2025-06-11-15-30";

      src = final.fetchFromGitHub {
        owner = "GigiaJ";
        repo = "cinny";
        rev = "1b281fe37b29e4b4a36d8bc3007a9abf2240ffff";
        hash = "sha256-3DKFOuFR7qYSvWsE/kAnaES/T9CFGNpmmOutE4o6vb4=";
      };

      npmDepsHash = "sha256-Z7GP3aorCnII7KfWajR8L+otiBxYC+uaMSYWcgmnZjw=";
      npmDeps = final.fetchNpmDeps {
        inherit src;
        name = "${pname}-${version}-npm-deps";
        hash = npmDepsHash;
      };
    });
  };
}
