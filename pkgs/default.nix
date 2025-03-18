{ pkgs }:
let
  inherit (pkgs) lib;
  sources = lib.callPackagesWith pkgs ../_sources/generated.nix { };
  mlnx-ofed-src = pkgs.stdenv.mkDerivation {
    pname = "mlnx-ofed-src";
    inherit (sources.mlnx-ofed-src) src version;
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
{
  # Function for building kernel modules
  mkKernelModules =
    { kernel, kernelModuleMakeFlags }:
    import ./kernel-modules {
      inherit pkgs mkUnpackScript mlnx-ofed-src;
      inherit kernel kernelModuleMakeFlags;
    };

  # Regular non-kernel module packages
  packages = import ./tools {
    inherit pkgs mkUnpackScript mlnx-ofed-src;
  };
}
