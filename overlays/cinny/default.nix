{
  channels,
  inputs,
  ...
}:

final: prev: {
  awesome-flake = (prev.awesome-flake or { }) // {
    cinny = prev.cinny-unwrapped.overrideAttrs (_old: rec {
      pname = "cinny-unwrapped";
      version = "feat/element-call";

      src = final.fetchFromGitHub {
        owner = "hazre";
        #owner = "cinnyapp";
        repo = "cinny";
        rev = version;
        hash = "sha256-13LOgxNFt8diZGyCGbDshlOsLEmUiUoR6wKK1pWAut8=";
      };

      npmDepsHash = "sha256-rFguxOvx/2ddJM6kP1CADIA9ysVwjq/JcjJ9eHV9nI0=";
      npmDeps = final.fetchNpmDeps {
        inherit src;
        name = "${pname}-${version}-npm-deps";
        hash = npmDepsHash;
      };
    });
  };
}
