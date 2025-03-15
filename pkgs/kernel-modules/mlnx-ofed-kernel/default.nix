{
  pkgs,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  mlnx-ofed-src,
  ...
}:
let
  kernelVersion = kernel.modDirVersion;
  kernelDir = "${kernel.dev}/lib/modules/${kernelVersion}";
  kernelModuleInstallFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];
in
stdenv.mkDerivation {
  pname = "mlnx-ofed-kernel";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = ''
    file=$(find ${mlnx-ofed-src}/SOURCES -name "mlnx-ofed-kernel_*.orig.tar.gz" | head -n1)
    if [ -z "$file" ]; then
      echo "Error: Could not find mlnx-ofed-kernel_*.orig.tar.gz in sources"
      exit 1
    fi
    tar --strip-components 1 -xzf "$file"
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  patchPhase = ''
    patchShebangs .

    substituteInPlace ./ofed_scripts/configure \
      --replace-warn '/bin/cp' 'cp' \
      --replace-warn '/bin/rm' 'rm'
    substituteInPlace ./ofed_scripts/makefile \
      --replace-warn '/bin/ls' 'ls' \
      --replace-warn '/bin/cp' 'cp' \
      --replace-warn '/bin/rm' 'rm'
  '';

  configureScript = "./configure";

  configureFlags = [
    "--with-core-mod"
    "--with-user_mad-mod"
    "--with-user_access-mod"
    "--with-addr_trans-mod"
    "--with-mlx4-mod"
    "--with-mlx4_en-mod"
    "--with-mlx5-mod"
    "--with-ipoib-mod"
    "--with-srp-mod"
    "--with-rds-mod"
    "--with-iser-mod"
    "--kernel-sources=${kernelDir}/source"
    "--with-linux=${kernelDir}/source"
    "--with-linux-obj=${kernelDir}/build"
    "--modules-dir=${kernelDir}"
    "--kernel-version=${kernelVersion}"
  ];

  # Paralellize configure phase
  preConfigure = ''
    appendToVar configureFlags "-j$NIX_BUILD_CORES"
  '';

  enableParallelBuilding = true;

  makeFlags = kernelModuleMakeFlags ++ kernelModuleInstallFlags;

  installFlags = kernelModuleInstallFlags;

  meta = with pkgs.lib; {
    description = "Mellanox mlnx-ofed driver kernel module";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
