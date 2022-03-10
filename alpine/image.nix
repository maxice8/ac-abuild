{ pkgs, lib }:
let
  alpine-base = pkgs.dockerTools.pullImage
    {
      imageName = "docker.io/maxice8/alpine-container-abuild";
      imageDigest = "sha256:c60451c002229fb3b951d6f7f5f8d0b8499b68a8a0295ae1320a16ed3a185f59";
      sha256 = "03jf4cw52x2y9yl82l1rrb8rrd9p7rrk49akpqy4nxsny9xcb6s4";
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
