{
  lib,
  rdma-core,
  mkUnpackScript,
  mlnx-ofed-src,
  ...
}:

rdma-core.overrideAttrs (oldAttrs: {
  pname = "mlnx-rdma-core";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "rdma-core";

  meta =
    with lib;
    oldAttrs.meta
    // {
      description = "(Mellanox variant) ${oldAttrs.meta.description}";
      maintainers = with maintainers; [ codgician ];
    };
})
