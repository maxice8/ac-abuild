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
  outputs = { self, nixpkgs, ... }:
    let
      supportedSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      overlays.default = final: prev: {
        alpine-container-abuild = final.callPackage ./alpine-container-abuild.nix {
          image = final.callPackage ./alpine/image.nix { };
        };
        ac-abuild-shell-utils = final.callPackage ./shell-utils.nix { };
      };

      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
              self.inputs.atools.overlays.default
            ];
          };
        in
        {
          build-image = pkgs.callPackage ./alpine/image.nix { };
          build-alpine-container-abuild = pkgs.alpine-container-abuild;
          build-shell-utils = pkgs.ac-abuild-shell-utils;
        });
    };
}
