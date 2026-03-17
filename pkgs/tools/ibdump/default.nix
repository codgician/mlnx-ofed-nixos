{
  lib,
  stdenv,
  mkUnpackScript,
  mlnx-ofed-src,
  mlnx-rdma-core,
  ...
}:

stdenv.mkDerivation {
  pname = "ibdump";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "ibdump";

  buildInputs = [ mlnx-rdma-core ];

  # Build without MFT/mstflint firmware tools.
  # Note: mstflint in nixpkgs doesn't export internal libraries (cmdif, dev_mgt,
  # reg_access, tools_layouts) needed for direct hardware access. The basic
  # traffic sniffing functionality through ibverbs still works.
  makeFlags = [
    "WITHOUT_FW_TOOLS=yes"
    "PREFIX=${placeholder "out"}"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "InfiniBand traffic sniffer";
    homepage = "https://github.com/Mellanox/ibdump";
    license = licenses.bsd2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
