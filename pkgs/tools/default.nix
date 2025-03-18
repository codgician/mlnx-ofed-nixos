{
  pkgs,
  mkUnpackScript,
  mlnx-ofed-src,
}:

let
  inherit (pkgs) lib;
  callPackage = lib.callPackageWith (pkgs // mlnxRegularPkgs);
  mlnxRegularPkgs = lib.pipe ./. [
    builtins.readDir
    (lib.filterAttrs (_: type: type == "directory"))
    (lib.mapAttrs (name: _: callPackage ./${name} { inherit mkUnpackScript mlnx-ofed-src; }))
  ];
in
mlnxRegularPkgs
