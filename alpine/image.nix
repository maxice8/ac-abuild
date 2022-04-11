{ pkgs, lib }:
let
  alpine-base = pkgs.dockerTools.pullImage
    {
      imageName = "docker.io/maxice8/alpine-container-abuild";
      imageDigest = "sha256:f587d536c227f357bed413472b1d29ebf91e8d739459a971839af62e1b499740";
      sha256 = "04n8islfw3dp8rqz0005pzs50ww59y7kdiycnj20bqpicafviwri";
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
