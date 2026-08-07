{
  homeManagerModules,
  nixosModules,
  ...
}:
{
  flake = {
    inherit nixosModules homeManagerModules;

    homeModules = homeManagerModules;
  };
}
