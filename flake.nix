{
  description = "opinionated Alpine Linux image";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.atools = {
    type = "gitlab";
    host = "gitlab.alpinelinux.org";
    owner = "Leo";
    repo = "atools";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.maxice8-nix.url = "github:maxice8/nix-overlay";
  inputs.maxice8-nix.inputs.nixpkgs.follows = "nixpkgs";
  outputs = _:
    {
      overlays.default = final: prev: {
        alpine-container-abuild = final.callPackage ./alpine-container-abuild.nix {
          image = final.callPackage ./alpine/image.nix { };
        };
        ac-abuild-shell-utils = final.callPackage ./shell-utils.nix { };
      };
    };
}
