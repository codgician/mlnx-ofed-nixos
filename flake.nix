{
  description = "Mellanox mlnx-ofed drivers ported to NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
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
      overlays.default =
        final: prev:
        let
          mkMlnxPackages =
            {
              kernel ? null,
              kernelModuleMakeFlags ? null,
            }:
            import ./pkgs {
              pkgs = prev;
              inherit kernel kernelModuleMakeFlags;
            };

          mlnxRegularPkgs = builtins.removeAttrs (mkMlnxPackages { }) [ "kernelModules" ];

          # Function to extend kernelModules sets with our modules
          extendKernelModules =
            args@{ kernel, kernelModuleMakeFlags }:
            let
              mlnxKernelPkgs = (mkMlnxPackages args).kernelModules;
              # Filter valid derivations from imported kernel modules
              validDerivation = _: v: lib.isDerivation v && v ? override && v ? meta;
            in
            lib.filterAttrs validDerivation mlnxKernelPkgs;
        in
        mlnxRegularPkgs
        // {
          linuxKernel = prev.linuxKernel // {
            packagesFor =
              kernel:
              (prev.linuxKernel.packagesFor kernel).extend (
                lpself: lpsuper:
                (extendKernelModules {
                  inherit (lpsuper) kernel kernelModuleMakeFlags;
                })
              );
          };
        };

      # Packages
      packages = forAllSystems (system: (import ./pkgs { pkgs = mkPkgs system; }));

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
