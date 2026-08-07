{
  lib,
  binaryen,
  buildNpmPackage,
  cargo,
  fetchFromGitHub,
  nodejs,
  rustPlatform,
  rustc,
  wasm-bindgen-cli_0_2_125,
  wasm-pack,
  nix-update-script,
  extraBuildEnv ? { },
}:

buildNpmPackage (finalAttrs: {
  pname = "ente-web-auth";
  version = "4.4.25";

  src = fetchFromGitHub {
    owner = "ente";
    repo = "ente";

    # The npm frontend calls into the Rust workspace.
    sparseCheckout = [
      "rust"
      "web"
    ];

    tag = "auth-v${finalAttrs.version}";
    fetchSubmodules = true;

    # Changes because the Rust directory is now included.
    hash = "sha256-7tvpI1LvF1ue9JIxXkpT1bcA8USiZKgDQ/H0z4oWcjA=";
  };

  sourceRoot = "${finalAttrs.src.name}/web";

  /*
    Make Cargo dependencies available offline.

    cargoRoot is relative to sourceRoot, which is the web directory.
  */
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs)
      pname
      version
      src
      sourceRoot
      cargoRoot
      ;

    hash = "sha256-RWemVZmH/NAQ+yDv2jwLhpHZpcp8BK3lZ4GjHMVLGLA=";
  };

  cargoRoot = "../rust";

  # Keep the npm hash you already calculated.
  npmDepsHash = "sha256-l3blcSYnJVGDBMaFw/UUtgwbStsMs1o4WurqUvEoSlI=";

  # Keep this if your current successful npm dependency fetch used it.
  npmDepsFetcherVersion = 2;

  nativeBuildInputs = [
    binaryen
    cargo
    rustPlatform.cargoSetupHook
    rustc
    rustc.llvmPackages.lld
    nodejs
    wasm-bindgen-cli_0_2_125
    wasm-pack
  ];

  env = extraBuildEnv;

  postPatch = ''
    # sourceRoot is web, so the sibling Rust tree was not made writable.
    chmod -R u+w ../rust

    # npm's wasm-pack package is a downloader wrapper. Bypass it and call
    # the Nix-provided executable directly.
    for packageJSON in \
      packages/wasm/package.json \
      packages/wasm-core/package.json
    do
      substituteInPlace "$packageJSON" \
        --replace-fail \
          "wasm-pack " \
          ${lib.escapeShellArg "${wasm-pack}/bin/wasm-pack "}
    done
  '';

  npmBuildScript = "build:auth";

  installPhase = ''
    runHook preInstall

    cp -r apps/auth/out "$out"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "auth-v(.*)"
    ];
  };

  meta = {
    description = "Web client for Ente Auth";
    homepage = "https://ente.io/";
    changelog = "https://github.com/ente/ente/releases";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [
      surfaceflinger
      pinpox
      spaenny
    ];
    platforms = lib.platforms.all;
  };
})
