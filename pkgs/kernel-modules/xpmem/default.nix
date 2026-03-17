{
  lib,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  mkUnpackScript,
  mlnx-ofed-src,
  autoreconfHook,
  ...
}:

let
  kernelVersion = kernel.modDirVersion;
  kernelDir = "${kernel.dev}/lib/modules/${kernelVersion}";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "xpmem";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript finalAttrs.pname;

  nativeBuildInputs = [ autoreconfHook ] ++ kernel.moduleBuildDependencies;

  configureFlags = [
    "--with-kerneldir=${kernelDir}/build"
    "--with-kernelvers=${kernelVersion}"
    "--with-module-prefix=${placeholder "out"}"
  ];

  makeFlags = kernelModuleMakeFlags;

  buildFlags = [ "-C" "kernel" ];
  installFlags = [ "-C" "kernel" ];

  postInstall = ''
    # Remove init.d script (not needed on NixOS with systemd)
    rm -rf $out/etc
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Cross-partition memory (XPMEM) kernel module";
    homepage = "https://github.com/openucx/xpmem";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
})
