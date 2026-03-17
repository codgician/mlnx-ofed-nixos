{
  lib,
  sockperf,
  mkUnpackScript,
  mlnx-ofed-src,
  ...
}:

sockperf.overrideAttrs (oldAttrs: {
  pname = "mlnx-sockperf";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "sockperf";

  meta = oldAttrs.meta // {
    description = "(Mellanox variant) ${oldAttrs.meta.description}";
    maintainers = with lib.maintainers; [ codgician ];
  };
})
