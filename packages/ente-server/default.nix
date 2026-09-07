{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "ente-server";
  version = "4.4.25";

  src = fetchFromGitHub {
    owner = "ente-io";
    repo = "ente";
    tag = "auth-v${finalAttrs.version}";
    hash = "sha256-LmgfqLibMnL9N+5bv2MoTeR0xojqSgtIf9Bv/arjenk=";
  };

  sourceRoot = "${finalAttrs.src.name}/server";

  subPackages = [ "cmd/museum" ];
  vendorHash = "sha256-Nbh9fs+43e1iE1ujr9T5vu7K1QscG+jdq5+iad4HkDc=";

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
