# ac-abuild

A nix flake that provides:

- Docker Image ready for building Alpine Linux aports (this is not exported but used by the following).
- Shell script (`alpine-container-abuild`) for running abuild commands inside a container based on the image mentioned above with all the correct options, including loading the image into podman/docker on the first run and mapping the current user to the host.
- opinionated, but helpful shell scripts for many common activities related to aports.

## Getting started

To use it:

1. Add it to your `flake.nix` inputs.

```nix
# Example, adapt it to your situation
{
  inputs.ac-abuild.url = "github:maxice8/ac-abuild";
}
```

2. add your architecture under `<INPUT-NAME>.overlays.<SYSTEM>`.

```nix
# Example, adapt it to your situation
outputs = { nixpkgs, ac-abuild }:
  nixosConfigurations.example = nixpkgs.lib.nixosSystem {
    modules = [
      {
        nixpkgs.overlays = [ ac-abuild.overlays."x86_64-linux" ];
      }
    ];
  };
}
```

3. add `alpine-container-abuild` and optionally `ac-abuild-shell-utils` to your packages.

```nix
# Example, adapt it to your situation
environment.systemPackages = with pkgs; [ alpine-abuild-container ac-abuild-shell-utils ];
```

## Usage

After putting it in your configuration just rebuild your NixOS system or home-manager configuration.

## Under the hood

The docker image it creates is based on [maxice8/alpine-container-abuild](https://hub.docker.com/repository/docker/maxice8/alpine-container-abuild/).

The image is based on an [Alpine Linux](https://alpinelinux.org) image but with all actions that require a network, namely installing packages, and other actions like creating and configuring a `builder` user.

The `alpine-abuild-container` scripts does some `--uidmap` and `--gidmap` magic to map your current user and group id into the root of the container.

Relevant snippets from the script:

```sh
# Assignment of UID and GID variables, note that BASH defines
# UID for us in this case
: "${UID:="$(${pkgs.coreutils}/bin/id -u)"}"
: "${GID:="$(${pkgs.coreutils}/bin/id -g)"}"

# Part of the invocation of podman run
--uidmap=0:1:"$UID" \
--uidmap="$UID":0:1 \
--uidmap="$((UID + 1))":"$((UID + 1))":64536 \
--gidmap=0:1:"$GID" \
--gidmap="$GID":0:1 \
--gidmap="$((GID + 1))":"$((GID + 1))":64536 \
```

## Todo

1. add a specific subcommand called `shell` that ignores all checks and just runs the podman container with `--entrypoint=/bin/sh`
