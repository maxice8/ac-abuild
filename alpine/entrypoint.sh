#!/bin/sh
set -e

die() {
	printf >&2 "%s\n" "$@"
	exit 1
}

sudo install -d -o builder -g users "$HOME"/.abuild/

if [ ! -f "$HOME"/.abuild/abuild.conf ]; then
	cat <<- __EOF__ > "$HOME"/.abuild/abuild.conf
	export JOBS=1
	export MAKEFLAGS=-j\$JOBS
	__EOF__
fi

if ! grep -sq "^PACKAGER_PRIVKEY=" "$HOME"/.abuild/abuild.conf; then
	abuild-keygen -n -a
fi

sudo install -d -m775 -g abuild /var/cache/distfiles

for vpath in /home/builder/.abuild /home/builder/packages; do
	[ -d "$vpath" ] && sudo chown -R builder:users "$vpath"
done

sudo cp -v "$HOME"/.abuild/*.rsa.pub /etc/apk/keys/
sudo apk -U upgrade -a

exec "$(command -v abuild)" "$@"
