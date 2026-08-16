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
    let
      deployNodes = lib.mapAttrs (name: _node: config.flake.deploy.nodes.${name}) (
        lib.filterAttrs (
          _name: node:
          config.flake.nixosConfigurations.${node.configuration}.pkgs.stdenv.hostPlatform.system == system
        ) inventory.deployNodes
      );
    in
    {
      checks = inputs.deploy-rs.lib.${system}.deployChecks { nodes = deployNodes; };
    };
}
