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
    substituteInPlace sbin/* \
      --replace-fail '/bin/ls' 'ls' \
      --replace-fail '/bin/systemctl' 'systemctl' \
      --replace-fail '/sbin/sysctl' 'sysctl'

    substituteInPlace tsbin/* \
      --replace-fail '/bin/ls' 'ls' \
      --replace-fail '/bin/rm' 'rm' \
      --replace-fail '/usr/bin/bash' '/usr/bin/env bash' \
      --replace-fail '/bin/bash' 'bash' 
  '';

  enableParallelBuilding = true;

  installFlags = [ "DESTDIR=${placeholder "out"}" ];

  meta = with lib; {
    description = "Mellanox mlnx-tools for managing adapters";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
})
