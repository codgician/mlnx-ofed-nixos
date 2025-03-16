{
  description = "Mellanox mlnx-ofed proprietary drivers ported to NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
      overlays.default =
        final: prev:
        let
          mlnxPkgs = import ./pkgs { pkgs = prev; };
          mlnxKernelPkgs = mlnxPkgs.kernelModules;
          mlnxRegularPkgs = builtins.removeAttrs mlnxPkgs [ "kernelModules" ];

          # Function to extend kernelModules sets with our modules
          extendKernelModules =
            kernel:
            let
              # Override each kernel package to use the specific kernel
              mapKernelPkgs =
                _: value:
                if lib.isDerivation value && value ? override && value ? meta then
                  value.override { inherit kernel; }
                else
                  value;
            in
            lib.mapAttrs mapKernelPkgs mlnxKernelPkgs;

          # Find and extend all kernelModules in nixpkgs
          kernelOverrides = lib.mapAttrs (
            _: value:
            if lib.isAttrs value && value ? kernel && value.kernel ? modDirVersion then
              value.extend (lpself: lpsuper: (extendKernelModules lpsuper.kernel))
            else
              value
          ) prev;
        in
        mlnxRegularPkgs // kernelOverrides;

      # Packages
      packages = forAllSystems (system: (import ./pkgs { pkgs = mkPkgs system; }));

      # Text formatters
      formatter = forAllSystems (
        system:
        with nixpkgs.legacyPackages.${system};
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
        let
          pkgs = mkPkgs system;
        in
        pkgs.mkShell {
          buildInputs = with pkgs; [ git ];
          shellHook = ''
            nix repl --expr "builtins.getFlake (builtins.toString $(git rev-parse --show-toplevel))"
          '';
        }
      );
    };
}
