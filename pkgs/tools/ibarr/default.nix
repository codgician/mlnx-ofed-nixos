{
  lib,
  stdenv,
  cmake,
  pkg-config,
  mkUnpackScript,
  mlnx-ofed-src,
  mlnx-rdma-core,
  libnl,
  ...
}:

stdenv.mkDerivation {
  pname = "ibarr";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "ibarr";

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    mlnx-rdma-core
    libnl
  ];

  # Source has cmake_minimum_required(VERSION 2.8.11), but cmake 4.x requires >= 3.5
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  # Fix hardcoded absolute systemd service install path
  postPatch = ''
    sed -i "s|DESTINATION /lib/systemd/system|DESTINATION $out/lib/systemd/system|" CMakeLists.txt
  '';

  meta = with lib; {
    description = "InfiniBand address resolution daemon for RoCE";
    homepage = "https://github.com/Mellanox/ibarr";
    license = licenses.bsd2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
