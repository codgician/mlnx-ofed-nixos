rec {
  description = "A small subset of Mellanox mlnx-ofed drivers ported to NixOS";

  nixConfig = {
    allow-import-from-derivation = "true";
    extra-substituters = [ "https://mlnx-ofed-nixos.cachix.org" ];
    extra-trusted-public-keys = [
      "mlnx-ofed-nixos.cachix.org-1:jL/cqleOzhPw87etuHMeIIdAgFDKX8WnTBYMSBx3toI="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f system);
      mkPkgs = system: import nixpkgs { inherit system; };
    in
    {
      # Overlays
      overlay = self.overlays.default;
      overlays.default =
        final: prev:
        let
          inherit (import ./pkgs { pkgs = prev; }) mkKernelModules packages;
        in
        packages
        // {
          linuxKernel = prev.linuxKernel // {
            packagesFor =
              kernel:
              (prev.linuxKernel.packagesFor kernel).extend (
                lpself: lpsuper:
                mkKernelModules {
                  inherit (lpsuper) kernel kernelModuleMakeFlags;
                }
              );
          };
        };

      # NixOS modules
      nixosModules = {
        default = import ./modules;
        setupCacheAndOverlays = _: {
          nixpkgs.overlays = [ self.overlays.default ];
          nix.settings = {
            substituters = nixConfig.extra-substituters;
            trusted-public-keys = nixConfig.extra-trusted-public-keys;
          };
        };
      };

      # Packages
      packages = forAllSystems (system: (import ./pkgs { pkgs = mkPkgs system; }).packages);

      # Kernel packages
      linuxPackages_6_1 = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        (import ./pkgs { inherit pkgs; }).mkKernelModules {
          inherit (pkgs.linuxPackages_6_1) kernel kernelModuleMakeFlags;
        }
      );
      linuxPackages_6_6 = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        (import ./pkgs { inherit pkgs; }).mkKernelModules {
          inherit (pkgs.linuxPackages_6_6) kernel kernelModuleMakeFlags;
        }
      );
      linuxPackages_6_12 = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        (import ./pkgs { inherit pkgs; }).mkKernelModules {
          inherit (pkgs.linuxPackages_6_12) kernel kernelModuleMakeFlags;
        }
      );

      # Text formatters
      formatter = forAllSystems (
        system:
        with (mkPkgs system);
        writeShellApplication {
          name = "formatter";
          runtimeInputs = [
            treefmt
            nixfmt-rfc-style
            mdformat
            yamlfmt
          ];
          text = lib.getExe treefmt;
        }
      );

      # Dev shell that launches REPL
      devShells = forAllSystems (
        system: with (mkPkgs system); {
          default = mkShell {
            buildInputs = [
              nvfetcher
              jq
            ];
          };

          repl = mkShell {
            buildInputs = [ git ];
            shellHook = ''
              nix repl --expr "builtins.getFlake (builtins.toString $(git rev-parse --show-toplevel))"
              exit $?
            '';
          };
        }
      );
    };
}
