{
  lib,
  stdenv,
  callPackage,
  fetchFromGitLab,
  cmake,
  pkg-config,
  kdePackages,
}:

let
  libghostty-vt = callPackage ./libghostty-vt.nix { };
in

stdenv.mkDerivation {
  pname = "kwi";
  version = "0.1.0-unstable-2026-11-11";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "utilities";
    repo = "kwi";
    rev = "cd8fe4fe9a56cb10d7fb716b65030429a3d70d95";
    hash = "sha256-4jLWUvIyxzU5YaLY+Txo9IVgeVJn6MP+7XHMInhJAI4=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    kdePackages.extra-cmake-modules
    kdePackages.wrapQtAppsHook
  ];

  buildInputs = with kdePackages; [
    libghostty-vt
    qtbase
    qtdeclarative
    qtshadertools
    qtsvg
    qttools
    kcoreaddons
    kconfig
    kdbusaddons
    kguiaddons
    ki18n
    kirigami
    kpty
    kio
    knotifications
    kwindowsystem
    kparts
    kxmlgui
    kwidgetsaddons
    kcolorscheme
    kiconthemes
    kitemmodels
    qqc2-desktop-style
    kirigami-addons
    kirigami-app-components
    union
  ];

  cmakeFlags = [ (lib.cmakeBool "BUILD_TESTING" false) ];

  meta = {
    description = "Modern and fast terminal for KDE Plasma, built on libghostty-vt";
    homepage = "https://invent.kde.org/utilities/kwi";
    license = with lib.licenses; [
      gpl2Only
      gpl3Only
      lgpl21Only
      lgpl3Only
    ];
    mainProgram = "kwi";
    platforms = lib.platforms.linux;
  };
}
