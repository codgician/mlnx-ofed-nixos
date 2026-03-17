{
  lib,
  stdenv,
  mkUnpackScript,
  mlnx-ofed-src,
  autoreconfHook,
  ...
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xpmem";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript finalAttrs.pname;

  nativeBuildInputs = [ autoreconfHook ];

  configureFlags = [ "--disable-kernel-module" ];

  makeFlags = [ "udevrulesdir=$(out)/lib/udev/rules.d" ];
  installFlags = [ "udevrulesdir=$(out)/lib/udev/rules.d" ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Cross-partition memory (XPMEM) userspace library";
    homepage = "https://github.com/openucx/xpmem";
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
})
