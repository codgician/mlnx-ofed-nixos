{
  lib,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  kernelModuleInstallFlags,
  mkUnpackScript,
  bash,
  mlnx-ofed-kernel,
  mlnx-ofed-src,
  ...
}:
let
  kernelDir = "${kernel.dev}/lib/modules/${kernelVersion}";
  kernelVersion = kernel.modDirVersion;
  mlnxOfedKernel = mlnx-ofed-kernel.override {
    inherit kernel kernelModuleMakeFlags;
    copySource = true;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "virtiofs";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript finalAttrs.pname;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  patchPhase = ''
    substituteInPlace ./makefile \
      --replace-warn '/bin/ls' 'ls' \
      --replace-warn '/bin/bash' '${lib.getExe bash}'
    patchShebangs .
  '';

  enableParallelBuilding = true;

  makeFlags = kernelModuleMakeFlags ++ [
    "OFA_DIR=${mlnxOfedKernel}/src/ofa_kernel"
    "K_BUILD=${kernelDir}/build"
  ];

  installFlags = kernelModuleInstallFlags;

  meta = with lib; {
    description = "Mellanox DOCA SNAP virtiofs kernel module";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
})
