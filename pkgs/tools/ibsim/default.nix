{
  lib,
  stdenv,
  mkUnpackScript,
  mlnx-ofed-src,
  mlnx-rdma-core,
  ...
}:

stdenv.mkDerivation {
  pname = "ibsim";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "ibsim";

  buildInputs = [ mlnx-rdma-core ];

  makeFlags = [
    "prefix=${placeholder "out"}"
    "libpath=${mlnx-rdma-core}/lib"
  ];

  installFlags = [
    "prefix=${placeholder "out"}"
    "binpath=${placeholder "out"}/bin"
    "libdir=${placeholder "out"}/lib/umad2sim"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "InfiniBand fabric simulator for RDMA application development";
    homepage = "https://github.com/linux-rdma/ibsim";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
