{ pkgs, alpine-container-abuild }:
let
printerr-src = pkgs.writeShellScriptBin "printerr"
''
[ -n ''${PRINTERR_QUIET+x} ] || exit 0
[ $# -lt 1 ] && exit 1
${pkgs.coreutils}/bin/printf '\033[0m[ \033[31mERR\033[0m ] %s\n' "$*" 1>&2
'';
alpine-stable-prefix-src = pkgs.writeShellScriptBin "alpine-stable-prefix"
''
${pkgs.git}/bin/git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 1
[ $# -lt 1 ] && set -- "$(${pkgs.git}/bin/git branch --show-current)"

for branch in "$@"; do
  case "$branch" in
    3.10-*) echo 3.10 ;;
    3.11-*) echo 3.11 ;;
    3.12-*) echo 3.12 ;;
    3.13-*) echo 3.13 ;;
    3.14-*) echo 3.14 ;;
    3.15-*) echo 3.15 ;;
  esac
done
'';
ae-src = pkgs.writeShellScriptBin "ae"
''
: "''${APORTSDIR:=$PWD}"
: "''${EDITOR:=${pkgs.neovim}/bin/nvim}"

# switch to APORTSDIR
cd "$APORTSDIR"

[ "$#" -lt 1 ] && set -- "$(${pkgs.git}/bin/git branch --show-current)"

prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"

if [ -n "$prefix" ]; then
  set -- "$(${pkgs.coreutils}/bin/printf '%s' "$1" | ${pkgs.coreutils}/bin/cut -d - -f2-)"
fi

for repo in main community testing unmaintained non-free; do
  if [ -f $repo/"$1"/APKBUILD ]; then
    $EDITOR $repo/"$1"/APKBUILD; exit $?
  fi
done
${printerr-src}/bin/printerr no aport named "$1"
'';
au-src = pkgs.writeShellApplication {
  name = "au";
  runtimeInputs = [ pkgs.apk-tools pkgs.abuild ];
  text = ''
  : "''${AX_UNPACK:=${pkgs.abuild}/bin/abuild}"
  : "''${APORTSDIR:=$PWD}"
  : "''${FILEMANAGER:=${pkgs.ranger}/bin/ranger}"
  
  # switch to APORTSDIR
  cd "$APORTSDIR"
  
  [ "$#" -lt 1 ] && set -- "$(${pkgs.git}/bin/git branch --show-current)"
  
  prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"
  
  if [ -n "$prefix" ]; then
    set -- "$(${pkgs.coreutils}/bin/printf '%s' "$1" | ${pkgs.coreutils}/bin/cut -d - -f2-)"
  fi
  
  for repo in main community testing unmaintained non-free; do
    if [ -f "$APORTSDIR"/$repo/"$1"/APKBUILD ]; then
      (
        cd "$APORTSDIR"/$repo/"$1"
        "$AX_UNPACK" unpack
        # shellcheck disable=1090
        # We are sourcing so lets not fail if a variable
        # is unset for us
        set +u
        . "$APORTSDIR"/"$repo"/"$1"/APKBUILD
        workdir="$APORTSDIR"/$repo/"$1"/src
        if [ -n "''${builddir+x}" ]; then
          workdir="$workdir/$builddir"
        else
          # shellcheck disable=SC2154
          workdir="$workdir/$pkgname-$pkgver"
        fi
        "$FILEMANAGER" "$workdir"
      )
      exit $?
    fi
  done
  ${printerr-src}/bin/printerr no aport named "$1"
  '';
};
ab-src = pkgs.writeShellScriptBin "ab"
''
: "''${APORTSDIR:=$PWD}"
: "''${EDITOR:=${pkgs.neovim}/bin/nvim}"
: "''${AX_ABUILD:=${alpine-container-abuild}/bin/alpine-container-abuild}"

# switch to APORTSDIR
cd "$APORTSDIR"

[ "$#" -lt 1 ] && set -- "$(${pkgs.git}/bin/git branch --show-current)"

prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"

if [ -n "$prefix" ]; then
  set -- "$(${pkgs.coreutils}/bin/printf '%s' "$1" | ${pkgs.coreutils}/bin/cut -d - -f2-)"
fi

for repo in main community testing unmaintained non-free; do
  if [ -f $repo/"$1"/APKBUILD ]; then
  (
    cd "$APORTSDIR"/$repo/"$1"
    flags="-r"
    if [ -n "$AX_ABUILD_ARGS" ]; then
      flags="$flags $AX_ABUILD_ARGS"
    fi
    if [ -n "$AX_LOG" ]; then
      _mktemp="$(mktemp)"
      "$AX_ABUILD" $flags | tee "$_mktemp"
    else
      "$AX_ABUILD" $flags
    fi
  )
  exit $?
  fi
done
${printerr-src}/bin/printerr no aport named "$1"
'';
an-src = pkgs.writeShellScript "an"
''
: "''${APORTSDIR:=$PWD}"
: "''${FILEMANAGER:=${pkgs.ranger}/bin/ranger}"

# switch to APORTSDIR
cd "$APORTSDIR"

[ "$#" -lt 1 ] && set -- "$(${pkgs.git}/bin/git branch --show-current)"

prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"

if [ -n "$prefix" ]; then
  set -- "$(${pkgs.coreutils}/bin/printf '%s' "$1" | ${pkgs.coreutils}/bin/cut -d - -f2-)"
fi

for repo in main community testing unmaintained non-free; do
  if [ -f "$APORTSDIR"/$repo/"$1"/APKBUILD ]; then
    (
      cd "$APORTSDIR"/$repo/"$1"
      "$FILEMANAGER"
    )
    exit $?
  fi
done
${printerr-src}/bin/printerr no aport named "$1"
'';
ac-src = pkgs.writeShellApplication {
  name = "ac";
  runtimeInputs = [ pkgs.apk-tools pkgs.abuild ];
  text = ''
  : "''${AX_ASUM:=${pkgs.abuild}/bin/abuild}"
  : "''${APORTSDIR=$PWD}"

  cd "$APORTSDIR"

  [ "$#" -lt 1 ] && set -- "$(${pkgs.git}/bin/git branch --show-current)"

  prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"

  if [ -n "$prefix" ]; then
    set -- "$(${pkgs.coreutils}/bin/printf '%s' "$1" | ${pkgs.coreutils}/bin/cut -d - -f2-)"
  fi

  for repo in main community testing unmaintained non-free; do
    if [ -f $repo/"$1"/APKBUILD ]; then
      (
        cd $repo/"$1"
        $AX_ASUM checksum
      )
      exit $?
    fi
  done
  ${printerr-src}/bin/printerr no aport named "$1"
  '';
};
in
  pkgs.symlinkJoin {
    name = "scripts";
    paths = [
      ae-src
      ac-src
      ab-src
      au-src
      an-src
    ];
  }
