{
  pkgs,
  kernel ? pkgs.linuxPackages.kernel,
  kernelModuleMakeFlags ? kernel.commonMakeFlags ++ [
    "KBUILD_OUTPUT=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ],
  ...
}:
let
  inherit (pkgs) lib;
  sources = lib.callPackagesWith pkgs ../_sources/generated.nix { };
  source = pkgs.stdenv.mkDerivation {
    pname = "mlnx-ofed-src";
    inherit (sources.mlnx-ofed-src) src version;
    unpackPhase = ''
      mkdir -p $out
      tar -C $out --strip-components 1 -xzf $src 
    '';
    dontBuild = true;
  };

  mlnxPkgs = {
    kernelPackages = import ./kernel-packages {
      inherit
        lib
        pkgs
        kernel
        kernelModuleMakeFlags
        ;
      mlnx-ofed-src = source;
    };

    mlnx-ofed-src = source;
  };
in
mlnxPkgs
