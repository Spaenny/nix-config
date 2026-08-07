{
  config,
  deployNode,
  inventory,
  inputs,
  lib,
  ...
}:
{
  flake.deploy.nodes = lib.mapAttrs (
    _name: node: deployNode config.flake.nixosConfigurations.${node.configuration} node.hostname
  ) inventory.deployNodes;

  perSystem =
    { system, ... }:
    {
      checks = inputs.deploy-rs.lib.${system}.deployChecks config.flake.deploy;
    };
}
