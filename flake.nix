{
  description = "opinionated Alpine Linux image";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs, ... }:
  {
    homeManagerModule = import ./alpine-dev-env.nix;
  };
}
