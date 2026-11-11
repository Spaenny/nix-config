{
  lib,
  stdenv,
  fetchurl,
  ncurses,
  pkg-config,
  zig_0_17,
}:

# Kwi needs libghostty-vt >= 1.0, nixpkgs only ships an unstable 0.1.0 snapshot.
# Sources and the Zig version follow Kwi's .flatpak-manifest.json.
stdenv.mkDerivation (finalAttrs: {
  pname = "libghostty-vt";
  version = "1.0.0";

  src = fetchurl {
    url = "https://release.files.ghostty.org/libghostty-vt/${finalAttrs.version}/libghostty-vt-${finalAttrs.version}.tar.gz";
    hash = "sha256-Sm73WL5yGSPhlp57gbRD3MktjdP7WjlgDAOogXp1NnY=";
  };

  # Vendored Zig packages, passed to `zig build --system` so the build stays offline.
  deps = fetchurl {
    url = "https://release.files.ghostty.org/libghostty-vt/${finalAttrs.version}/libghostty-vt-${finalAttrs.version}-deps.tar.gz";
    hash = "sha256-TV6l5Ejkx+qPtVzLqoZo8ql9RPQ4zugx4rfs0WLYXCk=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [
    ncurses
    pkg-config
    zig_0_17
  ];

  postUnpack = ''
    mkdir zig-packages
    tar -xzf "$deps" -C zig-packages --strip-components=1
  '';

  dontSetZigDefaultFlags = true;

  zigBuildFlags = [
    "--system"
    "../zig-packages"
    "-Dcpu=baseline"
    "-Doptimize=ReleaseFast"
  ];

  doCheck = false;

  outputs = [
    "out"
    "dev"
  ];

  postInstall = ''
    mkdir -p "$dev/lib"
    mv "$out/lib/libghostty-vt.a" "$dev/lib/"
  '';

  # The headers, static library and metadata live in $dev, the shared library in $out.
  # ghostty-vt-config.cmake marks the shared libdir line for exactly this rewrite.
  postFixup = ''
    substituteInPlace "$dev/lib/pkgconfig/libghostty-vt-static.pc" \
      --replace-fail "$out" "$dev"
    substituteInPlace "$dev/lib/cmake/ghostty-vt/ghostty-vt-config.cmake" \
      --replace-fail 'set(_ghostty_vt_shared_libdir "''${_ghostty_vt_libdir}")' \
                     'set(_ghostty_vt_shared_libdir "'"$out"'/lib")'
  '';

  meta = {
    description = "Ghostty's VT (terminal sequence) parsing library";
    homepage = "https://ghostty.org/";
    license = lib.licenses.mit;
    platforms = zig_0_17.meta.platforms;
  };
})
