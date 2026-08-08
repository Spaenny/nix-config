_final: prev:

let
  redlibSrc = prev.fetchFromGitHub {
    owner = "Silvenga";
    repo = "redlib";
    rev = "af002ab216d271890e715c2d3413f7193c07c640";
    hash = "sha256-Ny/pdBZFgUAV27e3wREPV8DUtP3XfMdlw0T01q4b70U=";
  };
in
{
  redlib = prev.redlib.overrideAttrs (old: {
    version = "0.36.0-unstable-2026-04-04";

    src = redlibSrc;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      src = redlibSrc;
      name = "redlib-0.36.0-unstable-2026-04-04-vendor";
      hash = "sha256-eO3c7rlFna3DuO31etJ6S4c7NmcvgvIWZ1KVkNIuUqQ=";
    };

    nativeBuildInputs =
      (old.nativeBuildInputs or [ ])
      ++ (with prev; [
        cmake
        go
        perl
        git
        rustPlatform.bindgenHook
      ]);

    checkFlags = (old.checkFlags or [ ]) ++ [
      "--skip=oauth::tests::test_generic_web_backend"
      "--skip=oauth::tests::test_mobile_spoof_backend"
    ];
  });
}
