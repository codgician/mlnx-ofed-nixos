{
  pkgs,
  mlnxRegularPkgs ? { },
  kernel,
  kernelModuleMakeFlags,
  mkUnpackScript,
  mlnx-ofed-src,
}:

let
  inherit (pkgs) lib;
  callPackage = lib.callPackageWith (pkgs // mlnxRegularPkgs // mlnxKernelPkgs);
  mlnxKernelPkgs = lib.pipe ./. [
    builtins.readDir
    (lib.filterAttrs (_: type: type == "directory"))
    (lib.mapAttrs (
      name: _:
      callPackage ./${name} {
        inherit
          kernel
          kernelModuleMakeFlags
          mkUnpackScript
          mlnx-ofed-src
          ;
      }
    ))
  ];
in
mlnxKernelPkgs
