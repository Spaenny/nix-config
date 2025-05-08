{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  nodejs,
  yarnConfigHook,
  yarnBuildHook,
  nix-update-script,
  extraBuildEnv ? { },
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ente-web-auth";
  version = "4.3.6";

  src = fetchFromGitHub {
    owner = "ente-io";
    repo = "ente";
    sparseCheckout = [ "auth" ];
    tag = "auth-v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-/dWnaVll/kaKHTJ5gH18BR6JG5E6pF7/j+SgvE66b7M=";
  };
  sourceRoot = "${finalAttrs.src.name}/web";

  offlineCache = fetchYarnDeps {
    yarnLock = "${finalAttrs.src}/web/yarn.lock";
    hash = "sha256-Wu0/YHqkqzrmA5hpVk0CX/W1wJUh8uZSjABuc+DPxMA=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    nodejs
  ];

  # See: https://github.com/ente-io/ente/blob/main/web/apps/photos/.env
  env = extraBuildEnv;

  buildPhase = ''
    export NEXT_PUBLIC_ENTE_ENDPOINT=https://ente-api.monapona.dev
    yarn build:auth
  '';

  installPhase = ''
    runHook preInstall

    cp -r apps/auth/out $out

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
    changelog = "https://github.com/ente-io/ente/releases";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [
      surfaceflinger
      pinpox
      spaenny
    ];
    platforms = lib.platforms.all;
  };
})
