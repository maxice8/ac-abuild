{
  description = "opinionated Alpine Linux image";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    version = builtins.substring 0 8 self.lastModifiedDate;
    supportedSystems = [ "x86_64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
  in
  {
    packages = forAllSystems (system:
    let
      pkgs = nixpkgsFor.${system};
      other = self.packages.${system};
    in
    {
      shell-utils = pkgs.callPackage ./shell-utils.nix { other = other; };
      alpine-container-abuild = pkgs.callPackage ./alpine-container-abuild.nix {};
    });

    overlays = forAllSystems (system:
    let
      pkgs = nixpkgsFor.${system};
      our = self.packages.${system};
    in
    final:
    prev:
    {
      alpine-dev-shell-utils = pkgs.buildEnv {
        name = "alpine-dev-shell-utils";
        paths =
          [
            our.shell-utils
          ];
      };
      alpine-container-abuild = our.alpine-container-abuild;
    });
  };
}
