{
  lib,
  pkgs,
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
  pname = "mlnx-nvme";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript finalAttrs.pname;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  postPatch = ''
    substituteInPlace ./makefile \
      --replace-warn '/bin/ls' 'ls' \
      --replace-warn '/bin/bash' '${lib.getExe bash}'
    patchShebangs .
  '';

  enableParallelBuilding = true;

  # Fix GCC 14 build on Aarch64 platforms
  # from incompatible pointer type [-Wincompatible-pointer-types
  env.NIX_CFLAGS_COMPILE = lib.optionalString (stdenv.hostPlatform.isAarch64) "-Wno-error=incompatible-pointer-types";

  makeFlags = kernelModuleMakeFlags ++ [
    "OFA_DIR=${mlnxOfedKernel}/src/ofa_kernel"
    "K_BUILD=${kernelDir}/build"
  ];

  installFlags = kernelModuleInstallFlags;

  meta = with pkgs.lib; {
    description = "Mellanox virtiofs kernel module";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
})
