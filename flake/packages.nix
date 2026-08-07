{ packageSet, pkgsFor, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = pkgsFor system;
    in
    {
      _module.args.pkgs = pkgs;

      packages = packageSet pkgs;
      formatter = pkgs.nixfmt;
    };
}
