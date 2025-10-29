{ pkgs }:
let
  inherit (pkgs) lib;

  # Load package info from JSON
  packageInfo = builtins.fromJSON (builtins.readFile ../version.json);

  mlnx-ofed-src = pkgs.stdenv.mkDerivation {
    pname = "mlnx-ofed-src";
    inherit (packageInfo) version;
    src = pkgs.fetchurl { inherit (packageInfo) url sha256; };
    unpackPhase = ''
      mkdir -p $out
      tar -C $out --strip-components 1 -xzf $src 
    '';
    dontBuild = true;
  };

  # Make unpack script for inner packages
  mkUnpackScript = pname: ''
    pattern="${pname}_*.orig.tar.gz"
    file=$(find ${mlnx-ofed-src}/SOURCES -name "$pattern" | head -n1)
    if [ -z "$file" ]; then
      echo "Error: Could not find $pattern in SOURCES"
      exit 1
    fi
    tar --strip-components 1 -xzf "$file"
  '';

  # Build packages from a directory, allowing cross-package references
  mkPackageSet =
    extraArgs: path:
    lib.fix (
      self:
      let
        dirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir path);
        callPackage = lib.callPackageWith (pkgs // extraArgs // self);
        baseArgs = {
          inherit pkgs mkUnpackScript mlnx-ofed-src;
        }
        // extraArgs;
      in
      lib.mapAttrs (name: _: callPackage (path + "/${name}") baseArgs) dirs
    );

  # Regular non-kernel module packages
  regularPackages = mkPackageSet { } ./tools;

  # Function for building kernel modules with kernel-specific arguments
  mkKernelModules =
    {
      kernel,
      kernelModuleMakeFlags,
      kernelModuleInstallFlags ? [ "INSTALL_MOD_PATH=$(out)" ],
    }:
    mkPackageSet (
      regularPackages
      // {
        inherit kernel kernelModuleMakeFlags kernelModuleInstallFlags;
      }
    ) ./kernel-modules;
in
{
  inherit mkKernelModules;
  packages = regularPackages;
}
