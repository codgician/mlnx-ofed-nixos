{
  lib,
  ucx,
  mkUnpackScript,
  mlnx-ofed-src,
  mlnx-rdma-core,
  ...
}:

ucx.overrideAttrs (oldAttrs: {
  pname = "mlnx-ucx";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "ucx";

  # Replace rdma-core with mlnx-rdma-core
  buildInputs = lib.filter (p: p.pname or "" != "rdma-core") oldAttrs.buildInputs ++ [ mlnx-rdma-core ];

  configureFlags = [
    "--with-rdmacm=${lib.getDev mlnx-rdma-core}"
    "--with-verbs=${lib.getDev mlnx-rdma-core}"
    "--with-dc"
    "--with-rc"
    "--with-dm"
  ];

  meta = oldAttrs.meta // {
    description = "(Mellanox variant) ${oldAttrs.meta.description}";
    maintainers = with lib.maintainers; [ codgician ];
  };
})
