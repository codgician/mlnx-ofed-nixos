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
          mlnxRegularPkgs = builtins.removeAttrs (import ./pkgs { pkgs = prev; }) [ "kernelModules" ];

          # Function to extend kernelModules sets with our modules
          extendKernelModules =
            { kernel, kernelModuleMakeFlags }:
            let
              mlnxKernelPkgs =
                (import ./pkgs {
                  pkgs = prev;
                  inherit kernel kernelModuleMakeFlags;
                }).kernelModules;
            in
            lib.filterAttrs (
              _: value: lib.isDerivation value && value ? override && value ? meta
            ) mlnxKernelPkgs;

          # Find and extend all linuxPackages in nixpkgs
          kernelOverrides = lib.mapAttrs (
            key: value:
            if
              lib.isAttrs value && value ? kernel && value.kernel ? modDirVersion && value ? kernelModuleMakeFlags
            then
              value.extend (
                lpself: lpsuper:
                (extendKernelModules {
                  inherit (lpsuper) kernel kernelModuleMakeFlags;
                })
              )
            else
              value
          ) prev;
        in
        mlnxRegularPkgs // (lib.optionalAttrs prev.stdenv.hostPlatform.isLinux kernelOverrides);

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
