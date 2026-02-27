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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
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

      mkLinuxPackages =
        version: excluded:
        forAllSystems (
          system:
          let
            pkgs = mkPkgs system;
            kernelPackages = pkgs."linuxPackages_${version}";
          in
          lib.removeAttrs ((import ./pkgs { inherit pkgs; }).mkKernelModules {
            inherit (kernelPackages) kernel kernelModuleMakeFlags;
          }) excluded
        );
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
      linuxPackages_6_1 = mkLinuxPackages "6_1" [ "virtiofs" ];
      linuxPackages_6_6 = mkLinuxPackages "6_6" [ "virtiofs" ];
      linuxPackages_6_12 = mkLinuxPackages "6_12" [ ];
      linuxPackages_6_18 = mkLinuxPackages "6_18" [ ];

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

      devShells = forAllSystems (
        system: with (mkPkgs system); {
          default = mkShell {
            buildInputs = [ jq ];
          };
        }
      );

      apps = forAllSystems (
        system: with (mkPkgs system); {
          updater = {
            type = "app";
            meta = {
              description = "Checking for updates of mlnx-ofed source.";
              license = lib.licenses.mit;
              maintainers = with lib.maintainers; [ codgician ];
            };

            program = lib.getExe (writeShellApplication {
              name = "updater";
              runtimeInputs = [
                curl
                git
                jq
              ];
              text = builtins.readFile ./update.sh;
            });
          };
        }
      );
    };
}
