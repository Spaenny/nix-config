{
  pkgs,
  ...
}:
{
  programs.fish = {
    enable = true;
  };

  users.users.philipp = {
    isNormalUser = true;
    shell = pkgs.fish;
  };
}
