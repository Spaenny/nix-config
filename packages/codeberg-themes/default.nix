{
  lib,
  stdenvNoCC,
  fetchFromGitea,
}:

stdenvNoCC.mkDerivation {
  pname = "codeberg-themes";
  version = "17-unstable-2026-11-11";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "Codeberg-Infrastructure";
    repo = "forgejo";
    rev = "2254cb08246da2f78be062fc6c29a950933d217e";
    sha256 = "sha256-WB6yccT3cyCr+oImRyAo8iIyms2HzJQhdGQQ1A/IMcs=";
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
