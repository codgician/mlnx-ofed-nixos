{ pkgs }:
let
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
in
rec {
  # Function for building kernel modules
  mkKernelModules =
    { kernel, kernelModuleMakeFlags }:
    import ./kernel-modules {
      inherit pkgs mkUnpackScript mlnx-ofed-src;
      inherit kernel kernelModuleMakeFlags;
      mlnxRegularPkgs = packages;
    };

  # Regular non-kernel module packages
  packages = import ./tools {
    inherit pkgs mkUnpackScript mlnx-ofed-src;
  };
}
