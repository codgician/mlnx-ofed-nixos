{
  lib,
  callPackage,
  extraArgs,
  ...
}:

lib.pipe ./. [
  builtins.readDir
  (lib.filterAttrs (_: type: type == "directory"))
  (lib.mapAttrs (name: _: callPackage ./${name} extraArgs))
]
