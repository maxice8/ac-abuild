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
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
            (final: prev: {
              inherit (self.inputs.atools.packages.${system}) atools;
              inherit (self.inputs.maxice8-nix.packages.${system}) abuild;
            })
          ];
        });
    in
    rec {
      overlays.default = final: prev: {
        alpine-container-abuild = final.callPackage ./alpine-container-abuild.nix {
          image = final.callPackage ./alpine/image.nix { };
        };
        ac-abuild-shell-utils = final.callPackage ./shell-utils.nix { };
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system})
          alpine-container-abuild
          ac-abuild-shell-utils;
        default = packages.${system}.alpine-container-abuild;
      });
    };
}
