{
  lib,
  pkgs,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  mkUnpackScript,
  bash,
  mlnx-ofed-kernel,
  mlnx-ofed-src,
  ...
}:
let
  kernelModuleInstallFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];
  kernelDir = "${kernel.dev}/lib/modules/${kernelVersion}";
  kernelVersion = kernel.modDirVersion;
  mlnxOfedKernel = mlnx-ofed-kernel.override {
    inherit kernel kernelModuleMakeFlags;
    copySource = true;
  };
in
stdenv.mkDerivation rec {
  pname = "virtiofs";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript pname;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  patchPhase = ''
    patchShebangs .

    substituteInPlace ./makefile \
      --replace-warn '/bin/ls' 'ls' \
      --replace-warn '/bin/bash' '${lib.getExe bash}'
  '';

  enableParallelBuilding = true;

  makeFlags =
    kernelModuleMakeFlags
    ++ kernelModuleInstallFlags
    ++ [
      "OFA_DIR=${mlnxOfedKernel}/usr/src/ofa_kernel"
      "K_BUILD=${kernelDir}/build"
    ];

  installFlags = kernelModuleInstallFlags;

  meta = with pkgs.lib; {
    description = "Mellanox DOCA SNAP virtiofs kernel module";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
