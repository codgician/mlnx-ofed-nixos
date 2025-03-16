{
  lib,
  pkgs,
  kernel,
  kernelModuleMakeFlags,
  mlnx-ofed-src,
}:

lib.makeScope pkgs.newScope (
  self:
  lib.pipe ./. [
    builtins.readDir
    (lib.filterAttrs (_: type: type == "directory"))
    (lib.mapAttrs (
      name: _:
      self.callPackage ./${name} {
        inherit kernel kernelModuleMakeFlags mlnx-ofed-src;
      }
    ))
  ]
)
