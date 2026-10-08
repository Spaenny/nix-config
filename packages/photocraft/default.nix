{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  gtk3,
  libGL,
  libX11,
  libXcursor,
  libXi,
  libXrandr,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
}:

let
  version = "0.3.0";

  # wgpu/winit dlopen these at runtime (apps/photocraft/src/linux_libs.rs); rfd's GTK file
  # dialogs link gtk3. They are not DT_NEEDED entries, so they must be added to RUNPATH below.
  rpathLibs = [
    gtk3
    libGL
    libX11
    libXcursor
    libXi
    libXrandr
    libxcb
    libxkbcommon
    vulkan-loader
    wayland
  ];

  # Same commit the official release builds embed for Japanese UI/type fonts
  # (.github/workflows/release.yml -> CRAFT_FONTS_REF).
  craft-fonts = fetchFromGitHub {
    owner = "storytold";
    repo = "craft-fonts";
    rev = "abb83316d96aa59c1cf64784289e378fe9fa5695";
    hash = "sha256-e+6HpOYoAFTh6mNfGBBw2njnBzcE8W8+Jybv1+dKOCA=";
  };
in

rustPlatform.buildRustPackage {
  pname = "photocraft";
  inherit version;

  src = fetchFromGitHub {
    owner = "storytold";
    repo = "photocraft";
    rev = "60224d3fb7d4006bcfcc97603c1611b9b756aebd"; # v0.3.0
    hash = "sha256-MpvMiONXNd3w/NUQI3xZ8SKJFor42w0sxHHEFHnXgGw=";
  };

  cargoHash = "sha256-GytJ3eaPf18GDgAPxbKCZ6ibrxzLcnht4KLC/0UxrbM=";

  # Upstream packaging builds exactly these two binaries.
  cargoBuildFlags = [
    "-p"
    "photocraft"
    "-p"
    "photocraft-cli"
  ];

  env = {
    # Embed the Japanese/CJK fonts, as the official release builds do.
    CRAFT_FONTS_DIR = "${craft-fonts}";
    CRAFT_FONTS_REQUIRED = "1";
    # Build provenance for `--version` and the About dialog.
    PHOTOCRAFT_BUILD_SHA = "60224d3fb7d4006bcfcc97603c1611b9b756aebd";
    PHOTOCRAFT_BUILD_DATE = "2026-10-07";
  };

  # wgpu/winit dlopen these at runtime; rfd's GTK file dialogs link gtk3.
  buildInputs = rpathLibs;

  nativeBuildInputs = [ pkg-config ];

  # The test suite needs the corpora fetched with `cargo xtask corpus --all`.
  doCheck = false;

  postInstall = ''
    install -Dm644 packaging/linux/ai.storyteller.photocraft.desktop \
      $out/share/applications/ai.storyteller.photocraft.desktop
    install -Dm644 packaging/linux/ai.storyteller.photocraft.mime.xml \
      $out/share/mime/packages/ai.storyteller.photocraft.xml
    substituteInPlace packaging/linux/ai.storyteller.photocraft.metainfo.xml.in \
      --replace-fail "@VERSION@" "${version}" \
      --replace-fail "@DATE@" "2026-10-07"
    install -Dm644 packaging/linux/ai.storyteller.photocraft.metainfo.xml.in \
      $out/share/metainfo/ai.storyteller.photocraft.metainfo.xml
    mkdir -p $out/share/icons
    cp -R assets/app-icon/hicolor $out/share/icons/hicolor
  '';

  # Same pattern as nixpkgs' alacritty: the dlopen'd windowing/GPU libs need explicit
  # RUNPATH entries, or winit fails with WaylandError(Connection(NoWaylandLib)) on NixOS.
  postFixup = ''
    patchelf --add-rpath "${lib.makeLibraryPath rpathLibs}" \
      $out/bin/photocraft $out/bin/photocraft-cli
  '';

  meta = {
    description = "Open-source, native image editor with layers, masks, type and real PSD files";
    homepage = "https://getartcraft.com/apps/photocraft";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "photocraft";
    platforms = lib.platforms.linux;
  };
}
