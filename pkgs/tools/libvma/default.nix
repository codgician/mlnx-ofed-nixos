{
  lib,
  gcc15Stdenv,
  mkUnpackScript,
  mlnx-ofed-src,
  mlnx-rdma-core,
  libnl,
  pkg-config,
  autoreconfHook,
  ...
}:

# libvma hardcodes -Werror and its configure probes rely on it; GCC 16 introduces
# new diagnostics (non-c-typedef-for-linkage, unused-but-set-variable) that break the build.
gcc15Stdenv.mkDerivation {
  pname = "libvma";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "libvma";

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    mlnx-rdma-core
    libnl
  ];

  configureFlags = [
    "--with-ofed=${lib.getDev mlnx-rdma-core}"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Mellanox Messaging Accelerator (VMA) for high-performance socket acceleration";
    longDescription = ''
      VMA is a high-performance userspace library that boosts the performance of
      messaging and streaming applications by providing socket acceleration.
      Applications can use VMA transparently without code changes via LD_PRELOAD.
    '';
    homepage = "https://github.com/Mellanox/libvma";
    license = with licenses; [
      gpl2Only
      bsd2
    ];
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
