{ pkgs, lib }:
let
  alpine-base = pkgs.dockerTools.pullImage
    {
      imageName = "docker.io/maxice8/alpine-container-abuild";
      imageDigest = "sha256:4a3aadafdce5acf2c6c0189d11a10640564883a5f64d8297afc342ba15ae564c";
      sha256 = "00xr1zjlk1vv2wnl5k0n0g40x1a7ryp9k13md73yvlsf11k16gjs";
      finalImageName = "docker.io/maxice8/alpine-container-abuild";
      finalImageTag = "edge-x86_64";
    };
in
pkgs.dockerTools.buildImage {
  name = "alpine-container-abuild";

  fromImage = alpine-base;
  fromImageName = "alpine-container-abuild";
  fromImageTag = "edge-x86_64";

  config = {
    Entrypoint = [ "/home/builder/entrypoint.sh" ];
    WorkingDir = "/home/builder";
    User = "builder";
  };
}
