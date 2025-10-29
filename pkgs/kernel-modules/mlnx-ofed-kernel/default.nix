{
  lib,
  pkgs,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  kernelModuleInstallFlags,
  mkUnpackScript,
  mlnx-ofed-src,
  writeShellScriptBin,

  # Whether to copy source to $out/src/ofa_kernel
  copySource ? true,
  ...
}:
let
  kernelVersion = kernel.modDirVersion;
  kernelDir = "${kernel.dev}/lib/modules/${kernelVersion}";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "mlnx-ofed-kernel";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript finalAttrs.pname;

  nativeBuildInputs =
    kernel.moduleBuildDependencies
    # Mock update-alternatives in post build script
    ++ lib.optional copySource (writeShellScriptBin "update-alternatives" "true");

  postPatch = ''
    substituteInPlace ./ofed_scripts/configure \
      --replace-warn '/bin/cp' 'cp' \
      --replace-warn '/bin/rm' 'rm'
    substituteInPlace ./ofed_scripts/makefile \
      --replace-warn '/bin/ls' 'ls' \
      --replace-warn '/bin/cp' 'cp' \
      --replace-warn '/bin/rm' 'rm' \
      --replace-fail 'data_dir = /usr/share/mlnx_ofed' 'data_dir = /share/mlnx_ofed' \
      --replace-fail '$(INSTALL_MOD_PATH)/usr' '$(INSTALL_MOD_PATH)/'
  ''
  + lib.optionalString copySource ''
    # Patch post build script so source could be copied
    # this will be needed for building other mlnx kernel modules
    substituteInPlace ./ofed_scripts/dkms_ofed_post_build.sh \
      --replace-fail '/usr/src/ofa_kernel' '$out/src/ofa_kernel' \
      --replace-warn '/bin/cp' 'cp' \
      --replace-warn '/bin/rm' 'rm'
  ''
  + ''
    patchShebangs .
  '';

  configureScript = "./configure";

  configureFlags = [
    "--with-core-mod"
    "--with-user_access-mod"
    "--with-user_mad-mod"
    "--with-addr_trans-mod"
    "--with-mlx5-mod"
    "--with-mlx5-ipsec"
    "--with-mlx5_inf-mod"
    "--with-mlxdevm-mod"
    "--with-mlxfw-mod"
    "--with-ipoib-mod"
    "--with-user_mad-mod"
    "--with-linux=${kernelDir}/source"
    "--with-linux-obj=${kernelDir}/build"
    "--modules-dir=${kernelDir}"
    "--kernel-version=${kernelVersion}"
    "--prefix=$out"
  ];

  # Paralellize configure phase
  preConfigure = ''
    appendToVar configureFlags "-j$NIX_BUILD_CORES"
  '';

  enableParallelBuilding = true;

  makeFlags = kernelModuleMakeFlags;

  postBuild = lib.optionalString copySource ''
    # Run post build tasks
    export ofa_build_src=$out/src/ofa_kernel/${kernelVersion}
    ./ofed_scripts/dkms_ofed_post_build.sh
  '';

  installFlags = kernelModuleInstallFlags;

  meta = with pkgs.lib; {
    description = "Mellanox mlnx-ofed driver kernel module";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
})
