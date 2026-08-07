{
  homeManagerModules,
  nixosModules,
  ...
}:
{
  flake = {
    inherit nixosModules homeManagerModules;
  };
}
