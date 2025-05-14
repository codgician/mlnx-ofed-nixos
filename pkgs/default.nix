{ pkgs }:
let
  mlnx-ofed-src = pkgs.stdenv.mkDerivation rec {
    pname = "mlnx-ofed-src";
    version = "25.04-0.6.0.0";

    src = pkgs.fetchurl {
      url = "https://linux.mellanox.com/public/repo/doca/3.0.0-4.11.0-13611/extras/mlnx_ofed/MLNX_OFED_SRC-debian-${version}.tgz";
      sha256 = "sha256-tyMtcCqmRUuC6NjC0fUaPyzHBmyQqxtHViUQfOx/y1g=";
    };

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
