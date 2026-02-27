{
  lib,
  stdenv,
  python3,
  mstflint,
  mkUnpackScript,
  mlnx-ofed-src,
  mlnx-ethtool,
  ...
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mlnx-tools";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript finalAttrs.pname;

  nativeBuildInputs = [ ];

  runtimeInputs = [
    python3
    mstflint
    mlnx-ethtool
  ];

  postPatch = ''
    substituteInPlace sbin/common_irq_affinity.sh \
      --replace-fail '/bin/ls' 'ls'

    substituteInPlace sbin/mlnx_affinity \
      --replace-fail '/bin/systemctl' 'systemctl' \
      --replace-fail '/sbin/chkconfig' 'chkconfig'

    substituteInPlace sbin/compat_gid_gen \
      --replace-fail '/bin/echo' 'echo'

    substituteInPlace tsbin/mlnx_bf_configure \
      --replace-fail '/bin/ls' 'ls'

    substituteInPlace tsbin/sysctl_perf_tuning \
      --replace-fail '/bin/rm' 'rm' \
      --replace-fail '/sbin/sysctl' 'sysctl'

    patchShebangs .
  '';

  enableParallelBuilding = true;

  installFlags = [ "DESTDIR=${placeholder "out"}" ];

  meta = with lib; {
    description = "Mellanox mlnx-tools for managing adapters";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
})
