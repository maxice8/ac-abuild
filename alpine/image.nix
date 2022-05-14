{ pkgs, lib }:
let
  alpine-base = pkgs.dockerTools.pullImage
    {
      imageName = "docker.io/maxice8/alpine-container-abuild";
      imageDigest = "sha256:f81ba82d9b5a24adb02a92f0d6422a512b4dd228c7509179f6e9d288e0ae4f2b";
      sha256 = "1ipy00p9sxjk56bcipq97db7y1vqmm7njflx6xadrdhsbx4q5fiy";
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
