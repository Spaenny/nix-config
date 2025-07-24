{
  channels,
  inputs,
  ...
}:

final: prev: {
  inherit (channels.stable) prisma;
}
