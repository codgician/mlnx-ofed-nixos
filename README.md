# mlnx-ofed-nixos

[![build](https://github.com/codgician/mlnx-ofed-nixos/actions/workflows/build.yml/badge.svg)](https://github.com/codgician/mlnx-ofed-nixos/actions/workflows/build.yml)

A small subset of Mellanox OFED packages ported to NixOS.

**Work in progress, packages are untested and may actually NOT WORK**

Further docs will be available when the code is actually usable. Everything is subject to change.

To add packages provided in this flake to your package universe, simply use `overlays.default` provided in this flake.

To run a REPL and inspect everything this flake provides, simply run:

```bash
nix develop
```
