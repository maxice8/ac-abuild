{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.services.alpine-container-abuild;

  alpine-image = pkgs.callPackage ./alpine/image.nix { inherit (cfg) uid; };
  alpine-container-abuild = pkgs.callPackage ./alpine-container-abuild.nix
    {
      inherit alpine-image;
    };
  helper-shell-utils = pkgs.callPackage ./shell-utils.nix
    {
      inherit alpine-container-abuild;
    };
in
{
  options.services.alpine-container-abuild = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If enabled, a docker image will be created based on
        docker.io/maxice8/alpine-container-abuild.

        Alongside the docker image, a shell script called
        'alpine-container-abuild' will be made installed
        that abstracts all that is needed to run abuild
        inside a docker container for things like building
        packages.

        Other options of this module like 'uid' will modify
        the final result of the docker image.
      '';
    };

    uid = mkOption {
      type = types.int;
      default = 1000;
      description = ''
        UID of the account named 'builder' inside the docker
        image.

        The ID must match the UID of the user that is running
        the docker image as we use --userns=keep-id to allow
        access to the aports repository.
      '';
    };

    helper-shell-utils = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Install helpful but very opinionated shellscripts to
        interact with aports.

        This requires the service itself to be enabled.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      assertions =
        [
          {
            # Use '> 999' rather than '>= 1000' because the '>=' is easier
            # to miss if someone is reading this quickly
            assertion = cfg.uid > 999;
            message = "UIDs under 1000 are reserved for system services";
          }
        ];
      # Add the alpine-container-abuild shellscript
      # this should be enough to also bring the image
      # docker image
      home.packages = [ alpine-container-abuild ];
    })
    (mkIf cfg.helper-shell-utils {
      assertions =
        [
          {
            assertion = cfg.enable;
            message = "services.alpine-container-abuild.helper-shell-utils requires 'services.alpine-container-abuild.enable = true;'";
          }
        ];
      # Add helper shell-utils
      home.packages = [ helper-shell-utils ];
    })
  ];
}
