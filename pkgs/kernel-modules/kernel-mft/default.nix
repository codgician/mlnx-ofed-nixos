{
  lib,
  pkgs,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  mkUnpackScript,
  mlnx-ofed-src,
  ...
}:
let
  kernelDir = "${kernel.dev}/lib/modules/${kernelVersion}";
  kernelVersion = kernel.modDirVersion;
in
stdenv.mkDerivation rec {
  pname = "kernel-mft";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript pname;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  patchPhase = ''
    runHook prePatch
    patchShebangs .
    runHook postPatch
  '';

  buildPhase =
    let
      makeFlags = kernelModuleMakeFlags ++ [
        "CPUARCH=${stdenv.hostPlatform.system}"
        "KSRC=${kernelDir}/build"
        "KPVER=${kernelVersion}"
      ];
    in
    ''
      runHook preBuild

      make -j$NIX_BUILD_CORES \
        ${builtins.concatStringsSep " " makeFlags}

      runHook postBuild
    '';

  installPhase = ''
    install_dir=$out/lib/modules/${kernelVersion}/updates
    mkdir -p $install_dir
    cp ./mst_backward_compatibility/mst_pci/mst_pci.ko $install_dir
    cp ./mst_backward_compatibility/mst_pciconf/mst_pciconf.ko $install_dir
  ''
  + lib.optionalString (stdenv.hostPlatform.isPower) ''
    cp ./mst_backward_compatibility/mst_ppc/mst_ppc_pci_reset.ko $install_dir
  ''
  + lib.optionalString (stdenv.hostPlatform.isAarch64) ''
    cp ./misc_drivers/bf3_livefish/bf3_livefish.ko $install_dir
  '';

  meta = with pkgs.lib; {
    description = "Mellanox kernel-mft module";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
