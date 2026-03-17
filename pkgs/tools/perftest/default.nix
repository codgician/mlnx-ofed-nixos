{
  lib,
  stdenv,
  mkUnpackScript,
  mlnx-ofed-src,
  mlnx-rdma-core,
  pciutils,
  ...
}:

stdenv.mkDerivation {
  pname = "perftest";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "perftest";

  buildInputs = [
    mlnx-rdma-core
    pciutils
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "InfiniBand/RDMA performance tests";
    homepage = "https://github.com/linux-rdma/perftest";
    license = with licenses; [ gpl2Only bsd2 ];
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
