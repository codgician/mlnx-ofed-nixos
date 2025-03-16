{
  pkgs,
  rdma-core,
  mkUnpackScript,
  mlnx-ofed-src,
  ...
}:

rdma-core.overrideAttrs (oldAttrs: {
  pname = "mlnx-rdma-core";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "rdma-core";

  meta = with pkgs.lib; {
    description = "Mellanox RDMA Core Userspace Libraries and Daemons";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
})
