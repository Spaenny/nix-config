{
  channels,
  inputs,
  ...
}:

final: prev: {
  inherit (channels.unstable) prisma;
}
