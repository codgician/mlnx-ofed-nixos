# mlnx-ofed-nixos

[![build](https://github.com/codgician/mlnx-ofed-nixos/actions/workflows/build.yml/badge.svg)](https://github.com/codgician/mlnx-ofed-nixos/actions/workflows/build.yml)
![license](https://img.shields.io/github/license/codgician/mlnx-ofed-nixos)
![version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fcodgician%2Fmlnx-ofed-nixos%2Frefs%2Fheads%2Fmain%2Fversion.json&query=%24.version&label=version)

A small subset of Mellanox OFED packages ported to NixOS.

## Warning

This project is experimental and may stay experimental for a long time. Not all packages are fully tested, because I don't have the hardware to validate some of the scenarios like InfiniBand. Any help or suggestions are welcomed.

## Binary cache

- Address: `https://mlnx-ofed-nixos.cachix.org`
- Public key: `mlnx-ofed-nixos.cachix.org-1:jL/cqleOzhPw87etuHMeIIdAgFDKX8WnTBYMSBx3toI=`

## Quick start

### With flakes

This flake provides:

- `overlays.default` for adding packages into your `pkgs`.
- `nixosModules.default` for easy configuration.
- `nixosModules.setupCacheAndOverlays` for configure cache and overlays automatically.

A simple example flake would be:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mlnx-ofed-nixos = {
      url = "github:codgician/mlnx-ofed-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Add packages from this repo and set up binary cache
        inputs.mlnx-ofed-nixos.nixosModules.setupCacheAndOverlays
        # Add configuration options from this repo
        inputs.mlnx-ofed-nixos.nixosModules.default
        # Example configuration
        ({ config, ... }: {
          hardware.mlnx-ofed = {
            enable = true;
            nvme.enable = true;
            nfsrdma.enable = true;
            kernel-mft.enable = true;
          };
        })
      ];
    };
  };
}
```
