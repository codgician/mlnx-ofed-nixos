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
  pname = "mlnx-nvme";
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

  # Fix GCC 14 build on Aarch64 platforms
  # from incompatible pointer type [-Wincompatible-pointer-types
  env.NIX_CFLAGS_COMPILE = lib.optionalString (stdenv.hostPlatform.isAarch64) "-Wno-error=incompatible-pointer-types";

  makeFlags =
    kernelModuleMakeFlags
    ++ kernelModuleInstallFlags
    ++ [
      "OFA_DIR=${mlnxOfedKernel}/usr/src/ofa_kernel"
      "K_BUILD=${kernelDir}/build"
    ];

  installFlags = kernelModuleInstallFlags;

  meta = with pkgs.lib; {
    description = "Mellanox mlnx-nvme kernel module";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
