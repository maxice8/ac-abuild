# ac-abuild

A nix home-manager module supplying:

- Docker Image ready for building Alpine Linux aports.
- Shell script (called `alpine-container-abuild`) for running abuild commands inside a container based on the image mentioned above with all the correct options, including loading the image into podman/docker on the first run.
- optional, opinionated, but helpful shell scripts for many common activities related to aports.

## Getting started

Using [home-manager](https://github.com/rycee/home-manager) inside a flake:

```nix
{
  inputs = {
    home-manager.url = "github:rycee/home-manager";
    ac-abuild.url = "github:maxice8/ac-abuild";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ac-abuild,
    ...
  }: {
    nixosConfigurations.exampleHost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModule.home-manager
        {
          home-manager.users.exampleUser = { pkgs, ... }: {
            imports = [ ac-abuild.homeManagerModule ];
            services.alpine-container-abuild = {
              enable = true;
              helper-shell-utils = true;
            };
          };
        }
      ];
    };
  };
}
```

## Usage

After putting it in your configuration just rebuild your NixOS system or home-manager configuration.

## Configuration

It should work out-of-the-box if your user's `UID` is `1000`, if not then please set `services.alpine-container-abuild.uid` to the `UID` of your user.

This is necessary because we use `--userns=keep-id` in our shell script so we can access the `aports` repository.

## Under the hood

The docker image it creates is based on [maxice8/alpine-container-abuild](https://hub.docker.com/repository/docker/maxice8/alpine-container-abuild/).

The image is based on an [Alpine Linux](https://alpinelinux.org) image but with all actions that require a network, namely installing packages, and other actions like creating and configuring a `builder` user.

All that is done is to change the `UID` of the `builder` user if `services.alpine-container-abuild.uid` is not `1000` and set up some variables like `ENTRYPOINTS`.

## TODO

- Allow the user to pass a string to an option inside `services.alpine-container-abuild` that will be used as `runAsRoot` while creating the image, this will allow users to easily modify the resulting image.
- Make the module smarter by automatically detecting the UID of the user, this should make the configuration be unnecessary.
- Provide the resulting Docker Image and shell-scripts under packages for people that don't want/have home-manager.
