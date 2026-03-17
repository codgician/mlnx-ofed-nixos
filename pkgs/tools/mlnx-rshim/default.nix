{
  lib,
  rshim-user-space,
  mkUnpackScript,
  mlnx-ofed-src,
  ...
}:

rshim-user-space.overrideAttrs (oldAttrs: {
  pname = "mlnx-rshim";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "rshim";

  # Remove patches that may not apply to MLNX version
  patches = [ ];

  meta = oldAttrs.meta // {
    description = "(Mellanox variant) ${oldAttrs.meta.description}";
    maintainers = with lib.maintainers; [ codgician ];
  };
})
