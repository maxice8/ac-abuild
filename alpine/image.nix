{ pkgs, lib }:
let
  alpine-base = pkgs.dockerTools.pullImage
    {
      imageName = "docker.io/maxice8/alpine-container-abuild";
      imageDigest = "sha256:6db494577781d629d51e77a5a8d0288c1286557b92ac91d5f12007d47d8769ca";
      sha256 = "0glqij7sb8gwvx8c43ppshwfhma59jkd72rsi1z9g2454gflnwx4";
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
