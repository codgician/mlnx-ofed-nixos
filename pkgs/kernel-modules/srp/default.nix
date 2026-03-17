{
  lib,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  kernelModuleInstallFlags,
  mkUnpackScript,
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
  pname = "srp";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript finalAttrs.pname;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  postPatch = ''
    substituteInPlace ./makefile \
      --replace-fail '/bin/ls' 'ls' \
      --replace-fail '/bin/bash' 'bash'
    patchShebangs .
  '';

  enableParallelBuilding = true;

  makeFlags = kernelModuleMakeFlags ++ [
    "OFA_DIR=${mlnxOfedKernel}/src/ofa_kernel/${kernelVersion}"
    "K_BUILD=${kernelDir}/build"
  ];

  installFlags = kernelModuleInstallFlags;

  meta = with lib; {
    description = "SCSI RDMA Protocol (SRP) initiator kernel module";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
})
