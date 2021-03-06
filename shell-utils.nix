{ symlinkJoin
, writeShellApplication
, writeShellScriptBin
, writeTextFile
, atools
, abuild
, git
, coreutils
, neovim
, ranger
, apk-tools
, alpine-container-abuild
, less
, ...
}:
let
  printerr-src = writeShellScriptBin "printerr"
    ''
      [ -n ''${PRINTERR_QUIET+x} ] || exit 0
      [ $# -lt 1 ] && exit 1
      ${coreutils}/bin/printf '\033[0m[ \033[31mERR\033[0m ] %s\n' "$*" 1>&2
    '';
  alpine-stable-prefix-src = writeShellScriptBin "alpine-stable-prefix"
    ''
      ${git}/bin/git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 1
      [ $# -lt 1 ] && set -- "$(${git}/bin/git branch --show-current)"

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
  ae-src = writeShellScriptBin "ae"
    ''
      : "''${APORTSDIR:=$PWD}"
      : "''${EDITOR:=${neovim}/bin/nvim}"

      # switch to APORTSDIR
      cd "$APORTSDIR"

      [ "$#" -lt 1 ] && set -- "$(${git}/bin/git branch --show-current)"

      prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"

      if [ -n "$prefix" ]; then
        set -- "$(${coreutils}/bin/printf '%s' "$1" | ${coreutils}/bin/cut -d - -f2-)"
      fi

      for repo in main community testing unmaintained; do
        if [ -f $repo/"$1"/APKBUILD ]; then
          $EDITOR $repo/"$1"/APKBUILD; exit $?
        fi
      done
      ${printerr-src}/bin/printerr no aport named "$1"
    '';
  ae-fish-comp = writeTextFile {
    name = "ae.fish";
    destination = "/share/fish/vendor_completions.d/ae.fish";
    text = ''
      # Repositories
      set -l repositories main community testing unmaintained

      # Global commands
      complete -f -c ae -n "__fish_al_strict" -a "(__fish_atools_get_aports $repositories)"

      # grab all packages
      function __fish_atools_get_aports
        for repo in $argv
          ls $APORTSDIR/$repo | string replace -r '$' "\t$repo"
        end
      end

      # al is very strict with subcommands, there are no repetions
      function __fish_al_strict
        set -l cmd (commandline -poc)
        [ (count $cmd) -gt 1 ] && return 1
        [ (count $cmd) -lt 1 ] && return 1
        return 0
      end
    '';
  };
  au-src = writeShellApplication {
    name = "au";
    runtimeInputs = [ apk-tools abuild ];
    text = ''
      : "''${AX_UNPACK:=${abuild}/bin/abuild}"
      : "''${APORTSDIR:=$PWD}"
      : "''${FILEMANAGER:=${ranger}/bin/ranger}"
  
      # switch to APORTSDIR
      cd "$APORTSDIR"
  
      [ "$#" -lt 1 ] && set -- "$(${git}/bin/git branch --show-current)"
  
      prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"
  
      if [ -n "$prefix" ]; then
        set -- "$(${coreutils}/bin/printf '%s' "$1" | ${coreutils}/bin/cut -d - -f2-)"
      fi
  
      for repo in main community testing unmaintained; do
        if [ -f "$APORTSDIR"/$repo/"$1"/APKBUILD ]; then
          (
            cd "$APORTSDIR"/$repo/"$1"
            "$AX_UNPACK" unpack
            # We are sourcing so lets not fail if a variable
            # is unset for us
            set +u
            # shellcheck disable=1090
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
  au-fish-comp = writeTextFile {
    name = "au.fish";
    destination = "/share/fish/vendor_completions.d/au.fish";
    text = ''
      # Repositories
      set -l repositories main community testing unmaintained

      # Global commands
      complete -f -c au -n "__fish_al_strict" -a "(__fish_atools_get_aports $repositories)"

      # grab all packages
      function __fish_atools_get_aports
        for repo in $argv
          ls $APORTSDIR/$repo | string replace -r '$' "\t$repo"
        end
      end

      # al is very strict with subcommands, there are no repetions
      function __fish_al_strict
        set -l cmd (commandline -poc)
        [ (count $cmd) -gt 1 ] && return 1
        [ (count $cmd) -lt 1 ] && return 1
        return 0
      end
    '';
  };
  ab-src = writeShellScriptBin "ab"
    ''
      : "''${APORTSDIR:=$PWD}"
      : "''${EDITOR:=${neovim}/bin/nvim}"
      : "''${AX_ABUILD:=${alpine-container-abuild}/bin/alpine-container-abuild}"

      # switch to APORTSDIR
      cd "$APORTSDIR"

      [ "$#" -lt 1 ] && set -- "$(${git}/bin/git branch --show-current)"

      prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"

      if [ -n "$prefix" ]; then
        set -- "$(${coreutils}/bin/printf '%s' "$1" | ${coreutils}/bin/cut -d - -f2-)"
      fi

      for repo in main community testing unmaintained; do
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
  ab-fish-comp = writeTextFile {
    name = "ab.fish";
    destination = "/share/fish/vendor_completions.d/ab.fish";
    text = ''
      # Repositories
      set -l repositories main community testing unmaintained

      # Global commands
      complete -f -c ab -n "__fish_al_strict" -a "(__fish_atools_get_aports $repositories)"

      # grab all packages
      function __fish_atools_get_aports
        for repo in $argv
          ls $APORTSDIR/$repo | string replace -r '$' "\t$repo"
        end
      end

      # al is very strict with subcommands, there are no repetions
      function __fish_al_strict
        set -l cmd (commandline -poc)
        [ (count $cmd) -gt 1 ] && return 1
        [ (count $cmd) -lt 1 ] && return 1
        return 0
      end
    '';
  };
  an-src = writeShellScriptBin "an"
    ''
      : "''${APORTSDIR:=$PWD}"
      : "''${FILEMANAGER:=${ranger}/bin/ranger}"

      # switch to APORTSDIR
      cd "$APORTSDIR"

      [ "$#" -lt 1 ] && set -- "$(${git}/bin/git branch --show-current)"

      prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"

      if [ -n "$prefix" ]; then
        set -- "$(${coreutils}/bin/printf '%s' "$1" | ${coreutils}/bin/cut -d - -f2-)"
      fi

      for repo in main community testing unmaintained; do
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
  an-fish-comp = writeTextFile {
    name = "an";
    destination = "/share/fish/vendor_completions.d/an.fish";
    text = ''
      # Repositories
      set -l repositories main community testing unmaintained

      # Global commands
      complete -f -c an -n "__fish_al_strict" -a "(__fish_atools_get_aports $repositories)"

      # grab all packages
      function __fish_atools_get_aports
        for repo in $argv
          ls $APORTSDIR/$repo | string replace -r '$' "\t$repo"
        end
      end

      # al is very strict with subcommands, there are no repetions
      function __fish_al_strict
        set -l cmd (commandline -poc)
        [ (count $cmd) -gt 1 ] && return 1
        [ (count $cmd) -lt 1 ] && return 1
        return 0
      end
    '';
  };
  ac-src = writeShellApplication {
    name = "ac";
    runtimeInputs = [ apk-tools abuild ];
    text = ''
      : "''${AX_ASUM:=${abuild}/bin/abuild}"
      : "''${APORTSDIR=$PWD}"

      cd "$APORTSDIR"

      [ "$#" -lt 1 ] && set -- "$(${git}/bin/git branch --show-current)"

      prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"

      if [ -n "$prefix" ]; then
        set -- "$(${coreutils}/bin/printf '%s' "$1" | ${coreutils}/bin/cut -d - -f2-)"
      fi

      for repo in main community testing unmaintained; do
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
  ac-fish-comp = writeTextFile {
    name = "ac.fish";
    destination = "/share/fish/vendor_completions.d/ac.fish";
    text = ''
      # Repositories
      set -l repositories main community testing unmaintained

      # Global commands
      complete -f -c ac -n "__fish_al_strict" -a "(__fish_atools_get_aports $repositories)"

      # grab all packages
      function __fish_atools_get_aports
        for repo in $argv
          ls $APORTSDIR/$repo | string replace -r '$' "\t$repo"
        end
      end

      # al is very strict with subcommands, there are no repetions
      function __fish_al_strict
        set -l cmd (commandline -poc)
        [ (count $cmd) -gt 1 ] && return 1
        [ (count $cmd) -lt 1 ] && return 1
        return 0
      end
    '';
  };
  al-src = writeShellScriptBin "al"
    ''
      : "''${APORTSDIR:=$PWD}"
      : "''${APKBUILD_LINT:=${atools}/bin/apkbuild-lint}"
      : "''${APORTS_LINT:=${atools}/bin/aports-lint}"
      : "''${SECFIXES_CHECK:=${atools}/bin/secfixes-check}"

      # switch to APORTSDIR
      cd "$APORTSDIR"

      [ "$#" -lt 1 ] && set -- "$(${git}/bin/git branch --show-current)"

      prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"

      if [ -n "$prefix" ]; then
        set -- "$(${coreutils}/bin/printf '%s' "$1" | ${coreutils}/bin/cut -d - -f2-)"
      fi

      for repo in main community testing unmaintained; do
        if [ -f "$APORTSDIR"/$repo/"$1"/APKBUILD ]; then
          (
            cd "$APORTSDIR"/$repo/"$1"
            "$APKBUILD_LINT" ./APKBUILD
            "$APORTS_LINT" ./APKBUILD
            "$SECFIXES_CHECK" ./APKBUILD
          )
          exit $?
        fi
      done
      ${printerr-src}/bin/printerr no aport named "$1"
    '';
  al-fish-comp = writeTextFile {
    name = "al.fish";
    destination = "/share/fish/vendor_completions.d/al.fish";
    text = ''
      # Repositories
      set -l repositories main community testing unmaintained
    
      # Global commands
      complete -f -c al -n "__fish_al_strict" -a "(__fish_atools_get_aports $repositories)"
    
      # grab all packages
      function __fish_atools_get_aports
        for repo in $argv
          ls $APORTSDIR/$repo | string replace -r '$' "\t$repo"
        end
      end
    
      # al is very strict with subcommands, there are no repetions
      function __fish_al_strict
        set -l cmd (commandline -poc)
        [ (count $cmd) -gt 1 ] && return 1
        [ (count $cmd) -lt 1 ] && return 1
        return 0
      end
    '';
  };
  ad-src = writeShellScriptBin "ad"
    ''
      : "''${APORTSDIR:=$PWD}"

      # switch to APORTSDIR
      cd "$APORTSDIR"

      [ "$#" -lt 1 ] && set -- "$(${git}/bin/git branch --show-current)"

      prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"

      if [ -n "$prefix" ]; then
        set -- "$(${coreutils}/bin/printf '%s' "$1" | ${coreutils}/bin/cut -d - -f2-)"
      fi

      for repo in main community testing unmaintained; do
        if [ -f "$APORTSDIR"/$repo/"$1"/APKBUILD ]; then
          cd "$APORTSDIR"/"$repo"/"$1"
          # Run podman with a different entrypoint
          output="$(AC_ABUILD_ARGS="--entrypoint=/home/builder/apkg-diff" \
          ${alpine-container-abuild}/bin/alpine-container-abuild \
          size depends provides files)"
            printf '%s\n' "$output" | ${less}/bin/less -r --quit-if-one-screen
          exit $?
        fi
      done
      ${printerr-src}/bin/printerr no aport named "$1"
    '';

  ad-fish-comp = writeTextFile {
    name = "ad.fish";
    destination = "/share/fish/vendor_completions.d/ad.fish";
    text = ''
      # Repositories
      set -l repositories main community testing unmaintained

      # Global commands
      complete -f -c ad -n "__fish_al_strict" -a "(__fish_atools_get_aports $repositories)"

      # grab all packages
      function __fish_atools_get_aports
        for repo in $argv
          ls $APORTSDIR/$repo | string replace -r '$' "\t$repo"
        end
      end

      # al is very strict with subcommands, there are no repetions
      function __fish_al_strict
        set -l cmd (commandline -poc)
        [ (count $cmd) -gt 1 ] && return 1
        [ (count $cmd) -lt 1 ] && return 1
        return 0
      end
    '';
  };
  aw-src = writeShellApplication {
    name = "aw";
    runtimeInputs = [ apk-tools abuild ];
    text = ''
      : "''${AX_UNPACK:=${abuild}/bin/abuild}"
      : "''${APORTSDIR:=$PWD}"
  
      # switch to APORTSDIR
      cd "$APORTSDIR"
  
      [ "$#" -lt 1 ] && set -- "$(${git}/bin/git branch --show-current)"
  
      prefix="$(${alpine-stable-prefix-src}/bin/alpine-stable-prefix "$1")"
  
      if [ -n "$prefix" ]; then
        set -- "$(${coreutils}/bin/printf '%s' "$1" | ${coreutils}/bin/cut -d - -f2-)"
      fi
  
      for repo in main community testing unmaintained; do
        if [ -f "$APORTSDIR"/$repo/"$1"/APKBUILD ]; then
          (
            cd "$APORTSDIR"/$repo/"$1"
            "$AX_UNPACK" unpack
            # We are sourcing so lets not fail if a variable
            # is unset for us
            set +u
            # shellcheck disable=1090
            . "$APORTSDIR"/"$repo"/"$1"/APKBUILD
            workdir="$APORTSDIR"/$repo/"$1"/src
            if [ -n "''${builddir+x}" ]; then
              workdir="$workdir/$builddir"
            else
              # shellcheck disable=SC2154
              workdir="$workdir/$pkgname-$pkgver"
            fi
            cd "$workdir"
            git init >/dev/null
            git add .
            git commit -m "start"
            $SHELL
          )
          exit $?
        fi
      done
      ${printerr-src}/bin/printerr no aport named "$1"
    '';
  };
  aw-fish-comp = writeTextFile {
    name = "aw.fish";
    destination = "/share/fish/vendor_completions.d/aw.fish";
    text = ''
      # Repositories
      set -l repositories main community testing unmaintained

      # Global commands
      complete -f -c aw -n "__fish_al_strict" -a "(__fish_atools_get_aports $repositories)"

      # grab all packages
      function __fish_atools_get_aports
        for repo in $argv
          ls $APORTSDIR/$repo | string replace -r '$' "\t$repo"
        end
      end

      # al is very strict with subcommands, there are no repetions
      function __fish_al_strict
        set -l cmd (commandline -poc)
        [ (count $cmd) -gt 1 ] && return 1
        [ (count $cmd) -lt 1 ] && return 1
        return 0
      end
    '';
  };
  as-src = writeShellScriptBin "as"
    ''
      : "''${APORTSDIR:=$PWD}"
      : "''${AC_ABUILD:=${alpine-container-abuild}/bin/alpine-container-abuild}"

      # switch to APORTSDIR
      cd "$APORTSDIR"

      "$AC_ABUILD" shell "$@"
    '';
in
symlinkJoin {
  name = "scripts";
  paths = [
    ae-src
    ae-fish-comp
    ac-src
    ac-fish-comp
    ab-src
    ab-fish-comp
    au-src
    au-fish-comp
    an-src
    an-fish-comp
    al-src
    al-fish-comp
    ad-src
    ad-fish-comp
    aw-src
    aw-fish-comp
    as-src
  ];
}
