{
  lib,
  iproute2,
  mkUnpackScript,
  mlnx-ofed-src,
  ...
}:

iproute2.overrideAttrs (oldAttrs: rec {
  pname = "mlnx-iproute2";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript pname;

  meta =
    with lib;
    oldAttrs.meta
    // {
      description = "(Mellanox variant) ${oldAttrs.meta.description}";
      maintainers = with maintainers; [ codgician ];
    };
})
