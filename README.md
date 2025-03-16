# (WIP) mlnx-ofed-nixos

[![built with garnix](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fcodgician%2Fmlnx-ofed-nixos%3Fbranch%3Dmain)](https://garnix.io/repo/codgician/mlnx-ofed-nixos)

**Work in progress, packages are untested and may actually NOT WORK**

A small subset of Mellanox OFED packages ported to NixOS.

Further docs will be available when the code is actually usable. Everything is subject to change.

To add packages provided in this flake to your package universe, simply use `overlays.default` provided in this flake.

To run a REPL and inspect everything this flake provides, simply run:

```bash
nix develop
```
