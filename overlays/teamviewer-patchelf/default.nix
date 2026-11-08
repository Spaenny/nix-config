_final: prev:

let
  # patchelf 0.19.2 lays out the rewritten teamviewerd with a RW segment that
  # overlaps the code segment, and ld.so segfaults in dl_main before main()
  # runs. 0.15.2 (the version before the bump) produces a working binary.
  patchelf_0_15 = prev.patchelf.overrideAttrs {
    version = "0.15.2";
    src = prev.fetchurl {
      url = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2";
      hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
    };
  };
in
{
  # auto-patchelf calls the first patchelf in PATH, so this one wins over the
  # stdenv default.
  teamviewer = prev.teamviewer.overrideAttrs (old: {
    nativeBuildInputs = [ patchelf_0_15 ] ++ old.nativeBuildInputs;
  });
}
