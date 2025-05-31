{
  lib,
  stdenv,
  fetchFromGitea,
}:

stdenv.mkDerivation rec {
  pname = "codeberg-themes";
  version = "1.0";
  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "Codeberg-Infrastructure";
    repo = "forgejo";
    rev = "codeberg-11";
    sha256 = "sha256-Mud0GpnuGOL9Ys4dpL/xVmEHBMQrcuQgSu4NwEaNelE=";
  };

  unpackPhase = ''
    # We clone the repo and only extract the folder we need
    mkdir -p $out
    cp -r $src/web_src/css/themes $out/themes
  '';

  installPhase = ''
    # Create the required directories for installation
    mkdir -p $out/var/lib/forgejo/custom/public/assets/css
    mkdir -p $out/var/lib/forgejo/custom/public/assets/img

    # Move theme files
    cp -r $out/themes/* $out/var/lib/forgejo/custom/public/assets/css/

    # Install logo
    cp ${./logo.svg} $out/var/lib/forgejo/custom/public/assets/img/
  '';

  meta = with lib; {
    description = "Codeberg themes and logo for Forgejo";
    maintainers = with maintainers; [ spaenny ];
  };
}
