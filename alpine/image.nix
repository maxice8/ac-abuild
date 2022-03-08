{ pkgs, lib, uid }:
let
  alpine-base = pkgs.dockerTools.pullImage {
    imageName = "docker.io/maxice8/alpine-container-abuild";
    imageDigest = "sha256:294015c79d86973f16bcceeaa3ca60b4dd136117120c751353adce889eb4fcf3";
    sha256 = "0mkmq7kxq8v8f15b23sfpnl1wdphichpqnsbslj9vrp3si6cf0sq";
    finalImageTag = "edge-x86_64";
  };
in
pkgs.dockerTools.buildImage {
  name = "alpine-container-abuild";

  fromImage = alpine-base;
  fromImageName = "alpine-container-abuild";
  fromImageTag = "edge-x86_64";

  runAsRoot =
    if (uid != 1000) then
      ''
        #!/bin/sh
        sed -e 's|^builder:x:1000:100|builer:x:${uid}:100|g' -i /etc/passwd
      '' else '''';

  config = {
    Entrypoint = [ "/home/builder/entrypoint.sh" ];
    WorkingDir = "/home/builder";
    User = "builder";
  };
}
