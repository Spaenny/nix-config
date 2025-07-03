{
  channels,
  inputs,
  ...
}:

final: prev: {
  awesome-flake = (prev.awesome-flake or { }) // {
    technitium-dns-server = prev.technitium-dns-server.overrideAttrs (_old: rec {
      pname = "technitium-dns-server";
      version = "13.6.0";

      src = final.fetchFromGitHub {
        owner = "TechnitiumSoftware";
        repo = "DnsServer";
        tag = "v${version}";
        hash = "sha256-2OSuLGWdaiiPxyW0Uvq736wHKa7S3CHv79cmZZ86GRE=";
        name = "${pname}-${version}";
      };
    });
  };
}
