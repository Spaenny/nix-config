{
  channels,
  inputs,
  ...
}:

final: prev: {
  prisma = prev.prisma.overrideAttrs (_old: rec {
    pname = "prisma";

    meta.mainProgram = "prisma";
  });
}
