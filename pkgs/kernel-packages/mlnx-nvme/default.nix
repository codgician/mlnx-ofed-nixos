{
  lib,
  pkgs,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
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
stdenv.mkDerivation {
  pname = "mlnx-nvme";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = ''
    file=$(find ${mlnx-ofed-src}/SOURCES -name "mlnx-nvme_*.orig.tar.gz" | head -n1)
    if [ -z "$file" ]; then
      echo "Error: Could not find mlnx-nvme_*.orig.tar.gz in sources"
      exit 1
    fi
    tar --strip-components 1 -xzf "$file"
  '';

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
    description = "Mellanox mlnx-nvme kernel module";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
