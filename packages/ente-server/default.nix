{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "ente-server";
  version = "4.4.26";

  src = fetchFromGitHub {
    owner = "ente-io";
    repo = "ente";
    tag = "auth-v${finalAttrs.version}";
    hash = "sha256-4jHe+nomwFwz1kVjzQlSi4inKQ2dg80K0x3/UyoOU7E=";
  };

  sourceRoot = "${finalAttrs.src.name}/server";

  subPackages = [ "cmd/museum" ];
  vendorHash = "sha256-iiytPsRsu0iBqDwSr5NavRfWOd/7ZLd5KBpLDuTkbz0=";

  env.CGO_ENABLED = 0;

  postInstall = ''
    install -d "$out/share/ente-server"
    cp -r configurations migrations mail-templates web-templates "$out/share/ente-server/"
  '';

  meta = {
    description = "Ente server backend for Ente Auth";
    homepage = "https://ente.io/";
    changelog = "https://github.com/ente-io/ente/releases";
    license = lib.licenses.agpl3Only;
    mainProgram = "museum";
    platforms = lib.platforms.linux;
  };
})
