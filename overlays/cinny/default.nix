{ namespace }:
final: prev: {
  ${namespace} = (prev.${namespace} or { }) // {
    cinny = prev.cinny-unwrapped.overrideAttrs (_old: rec {
      pname = "cinny-unwrapped";
      version = "dev";

      src = final.fetchFromGitHub {
        owner = "cinnyapp";
        repo = "cinny";
        rev = version;
        hash = "sha256-w9t5Y1vqYIa7Ow8mixdskxk4ZyC/gKjU32iHCVmq0rM=";
      };

      npmDepsHash = "sha256-MTx0MoXa4+sWagrUDMWzEK2ofRqcZHbSyPiO3PGz+JM=";
      npmDeps = final.fetchNpmDeps {
        inherit src;
        name = "${pname}-${version}-npm-deps";
        hash = npmDepsHash;
      };
    });
  };
}
