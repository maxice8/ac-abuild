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
    in
    {
      packages = nixpkgs.lib.genAttrs supportedSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          alpine-container-abuild = pkgs.callPackage ./alpine-container-abuild.nix {
            image = pkgs.callPackage ./alpine/image.nix { };
          };
          ac-abuild-shell-utils = pkgs.callPackage ./shell-utils.nix {
            inherit (self.packages.${system}) alpine-container-abuild;
            inherit (self.inputs.atools.packages.${system}) atools;
            inherit (self.inputs.maxice8-nix.packages.${system}) abuild;
          };
          default = self.packages.${system}.alpine-container-abuild;
        });
    };
}
