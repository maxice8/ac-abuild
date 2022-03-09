{
  description = "opinionated Alpine Linux image";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.atools = {
    type = "gitlab";
    host = "gitlab.alpinelinux.org";
    owner = "Leo";
    repo = "atools";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, flake-utils, atools, ... }:
    let
      inherit (flake-utils.lib) system;
      linuxSystems =
        [
          system.x86_64-linux
          system.i686-linux
          system.aarch64-linux
        ];
    in
    flake-utils.lib.eachSystem linuxSystems
      (system:
        let
          pkgs = import nixpkgs
            {
              inherit system;
              overlays = [ self.overlays.${system} atools.overlays.${system} ];
            };
        in
        rec
        {
          packages = {
            alpine-container-abuild = pkgs.callPackage ./alpine-container-abuild.nix {
              image = pkgs.callPackage ./alpine/image.nix { };
            };
            ac-abuild-shell-utils = pkgs.callPackage ./shell-utils.nix { };
          };
          overlays = final: prev: {
            inherit (self.packages.${system})
              alpine-container-abuild
              ac-abuild-shell-utils;
          };
        }
      );
}
