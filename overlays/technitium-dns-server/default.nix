{ namespace }:
final: prev: {
  ${namespace} = (prev.${namespace} or { }) // {
    inherit (final) technitium-dns-server;
  };
}
