{
  self,
  packageSet,
  pkgsFor,
  ...
}:
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

      # Part of `nix flake check`, so CI fails on unformatted files.
      checks.formatting = pkgs.runCommand "check-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
        find ${self} -name '*.nix' -print0 | xargs -0 nixfmt --check
        touch $out
      '';
    };
}
