{
  lib,
  stdenvNoCC,
  fetchFromGitea,
}:

stdenvNoCC.mkDerivation {
  pname = "codeberg-themes";
  version = "17-unstable-2026-11-06";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "Codeberg-Infrastructure";
    repo = "forgejo";
    rev = "dc281500adb227682821b9ef8d0b85eb40c5e7cd";
    sha256 = "sha256-WUwIvZZv6blj8ubjuB7/mT9sqEErNHZRy42/QFtVjwU=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    assets=$out/var/lib/forgejo/custom/public/assets
    mkdir -p $assets/css $assets/{chroma,codemirror,markup} $assets/img

    # The theme files are CSS sources, not the compiled bundles Forgejo ships:
    # theme-codeberg-dark.css pulls in theme-forgejo-dark.css, which in turn
    # @imports ../chroma, ../codemirror and ../markup — relative to
    # /assets/css/ that resolves to /assets/{chroma,codemirror,markup}, and
    # Forgejo 17 serves no such files itself (they are bundled into its own
    # themes), so ship them alongside the css directory.
    cp -r $src/web_src/css/themes/* $assets/css/
    cp $src/web_src/css/chroma/*.css $assets/chroma/
    cp $src/web_src/css/codemirror/*.css $assets/codemirror/
    cp $src/web_src/css/markup/*.css $assets/markup/
    install -Dm444 ${./logo.svg} $assets/img/logo.svg

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
