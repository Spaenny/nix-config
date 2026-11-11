_final: prev:

let
  redlibSrc = prev.fetchFromGitHub {
    owner = "Silvenga";
    repo = "redlib";
    rev = "c0156ee2bbd1a7860ca82e4c3e9b8508b3f049d6";
    hash = "sha256-j6rT1oIGdxZtuAHXTpe1LiwGPUy8gKp5ifEdprHLIkE=";
  };
in
{
  redlib = prev.redlib.overrideAttrs (old: {
    version = "0.40.0-unstable-2026-10-24";

    src = redlibSrc;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      src = redlibSrc;
      name = "redlib-0.40.0-unstable-2026-10-24-vendor";
      hash = "sha256-XgHXqH4EF8TEOI+cKJ0Z2j6QYRCwGgv8bmY8gZpPN9c=";
    };

    nativeBuildInputs =
      (old.nativeBuildInputs or [ ])
      ++ (with prev; [
        cmake
        go
        perl
        git
        pkg-config
        rustPlatform.bindgenHook
      ]);

    # zstd-sys looks the library up via pkg-config.
    buildInputs = (old.buildInputs or [ ]) ++ [ prev.zstd ];

    checkFlags = (old.checkFlags or [ ]) ++ [
      "--skip=oauth::tests::test_generic_web_backend"
      "--skip=oauth::tests::test_mobile_spoof_backend"
    ];
  });
}
