{
  lib,
  pkgs,
  extraArgs ? { },
}:

lib.makeScope pkgs.newScope (
  self:
  lib.pipe ./. [
    builtins.readDir
    (lib.filterAttrs (_: type: type == "directory"))
    (lib.mapAttrs (name: _: self.callPackage ./${name} extraArgs))
  ]
)
