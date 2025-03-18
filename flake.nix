{
  description = "Mellanox mlnx-ofed drivers ported to NixOS";

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

      # Packages
      packages = forAllSystems (system: (import ./pkgs { pkgs = mkPkgs system; }).packages);

      # Kernel packages
      linuxPackages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        (import ./pkgs { inherit pkgs; }).mkKernelModules {
          inherit (pkgs.linuxPackages) kernel kernelModuleMakeFlags;
        }
      );
      linuxPackages_latest = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        (import ./pkgs { inherit pkgs; }).mkKernelModules {
          inherit (pkgs.linuxPackages_latest) kernel kernelModuleMakeFlags;
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
      devShell = forAllSystems (
        system:
        with (mkPkgs system);
        mkShell {
          buildInputs = [ git ];
          shellHook = ''
            nix repl --expr "builtins.getFlake (builtins.toString $(git rev-parse --show-toplevel))"
            exit $?
          '';
        }
      );
    };
}
