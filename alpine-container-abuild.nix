{ pkgs, image }:
pkgs.writeShellScriptBin "alpine-container-abuild"
  ''
    set -e
    set -u

    : "''${DABUILD_ARCH:=$(${pkgs.coreutils}/bin/uname -m)}"
    : "''${DABUILD_PACKAGES:=''${PWD%/aports/*}/packages}}"
    : "''${IMAGE_HASH:=$(basename ${image} | cut -d - -f 1)}"
    : "''${APORTSDIR:="$PWD"}"
    : "''${UID:="$(${pkgs.coreutils}/bin/id -u)"}"
    : "''${GID:="$(${pkgs.coreutils}/bin/id -g)"}"

    APORTSDIRNAME="$(${pkgs.coreutils}/bin/basename "$APORTSDIR")"

    die() {
      printf >&2 "%s\\n" "$@"
      exit 1
    }

    ## check running from within an `aports` tree
    if [ "''${PWD%*/$APORTSDIRNAME/*}" = "$PWD" ]; then
      die "Error: expecting to be run from within an aports tree!" \
        "Could not find '/aports/' in the current path: $APORTSDIR"
    fi

    DABUILD_PACKAGES="$DABUILD_PACKAGES/edge"

    ABUILD_VOLUMES="-v ''${PWD%/$APORTSDIRNAME/*}/aports:/home/builder/aports:Z \
      -v $DABUILD_PACKAGES:/home/builder/packages:Z"

    if [ -f "$HOME/.gitconfig" ]; then
      ABUILD_VOLUMES="$ABUILD_VOLUMES \
        -v $HOME/.gitconfig:/home/builder/.gitconfig"
    fi

    setup_named_volume() {
      local name=$1 dest=$2 single="''${3:-false}"
      local volume="dabuild-$name-edge-$DABUILD_ARCH"
      [ "$single" = "true" ] && volume="dabuild-$name"
      ABUILD_VOLUMES="$ABUILD_VOLUMES -v $volume:$dest"
    }

    setup_named_volume apkcache "/etc/apk/cache"
    setup_named_volume distfiles "/var/cache/distfiles" true
    setup_named_volume config "/home/builder/.abuild" true

    # Check if we have the docker image available and load it
    # with podman load
    #
    # Docker images -q will print the ID of the image if it exists
    # otherwise it will print 
    if [ "$(${pkgs.podman}/bin/podman images -q alpine-container-abuild:"$IMAGE_HASH" 2>/dev/null)" = "" ]; then
      ${pkgs.podman}/bin/podman load -i ${image}
    fi

    ${pkgs.podman}/bin/podman run --tty --interactive \
      $ABUILD_VOLUMES \
      --uidmap=0:1:"$UID" \
      --uidmap="$UID":0:1 \
      --uidmap="$((UID + 1))":"$((UID + 1))":65436 \
      --gidmap=0:1:"$GID" \
      --gidmap="$GID":0:1 \
      --gidmap="$((GID + 1))":"$((GID + 1))":65436 \
      --rm \
      --workdir /home/builder/aports/"''${PWD#*/$APORTSDIRNAME/}" \
      alpine-container-abuild:"$IMAGE_HASH" "$@"
  ''
