{
  lib,
  stdenvNoCC,
  fetchFromGitea,
}:

stdenvNoCC.mkDerivation {
  pname = "codeberg-themes";
  version = "1.0";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "Codeberg-Infrastructure";
    repo = "forgejo";
    rev = "8fbdf40e3224598b1e724b21e62b2e2f32910113";
    sha256 = "sha256-at+edBFcNr81kQWkH44Fih1IBrCJC72QDE+Spi+kxpc=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/var/lib/forgejo/custom/public/assets/css
    mkdir -p $out/var/lib/forgejo/custom/public/assets/img

    cp -r $src/web_src/css/themes/* $out/var/lib/forgejo/custom/public/assets/css/
    install -Dm444 ${./logo.svg} $out/var/lib/forgejo/custom/public/assets/img/logo.svg

    runHook postInstall
  '';

  meta = with lib; {
    description = "Codeberg themes and logo for Forgejo";
    homepage = "https://codeberg.org/Codeberg-Infrastructure/forgejo";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ spaenny ];
    platforms = platforms.all;
  };
}
