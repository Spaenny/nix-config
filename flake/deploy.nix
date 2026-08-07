{
  config,
  deployNode,
  inputs,
  ...
}:
{
  flake.deploy.nodes = {
    aquarius = deployNode config.flake.nixosConfigurations.aquarius "aquarius";
    blarm = deployNode config.flake.nixosConfigurations.blarm "blarm";
    dns-1 = deployNode config.flake.nixosConfigurations.dns "dns-1";
    dns-2 = deployNode config.flake.nixosConfigurations.dns "dns-2";
  };

  perSystem =
    { system, ... }:
    {
      checks = inputs.deploy-rs.lib.${system}.deployChecks config.flake.deploy;
    };
}
