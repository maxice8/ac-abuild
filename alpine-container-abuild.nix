{ pkgs }:
pkgs.writeShellScriptBin "alpine-container-abuild"
''
: "''${DABUILD_ARCH:=$(${pkgs.coreutils}/bin/uname -m)}"
: "''${DABUILD_PACKAGES:=''${PWD%/aports/*}/packages}}"

die() {
  printf >&2 "%s\\n" "$@"
  exit 1
}

## check running from within an `aports` tree
if [ "''${PWD%*/aports/*}" = "$PWD" ]; then
  die "Error: expecting to be run from within an aports tree!" \
    "Could not find '/aports/' in the current path: $PWD"
fi

DABUILD_PACKAGES="$DABUILD_PACKAGES/edge"

ABUILD_VOLUMES="-v ''${PWD%/aports/*}/aports:/home/builder/aports:Z \
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

${pkgs.podman}/bin/podman run --tty --interactive \
  $ABUILD_VOLUMES \
  --userns=keep-id \
  --rm \
  --workdir /home/builder/aports/"''${PWD#*/aports/}" \
  docker.io/maxice8/alpine-container-abuild:edge-$DABUILD_ARCH "$@"
''
