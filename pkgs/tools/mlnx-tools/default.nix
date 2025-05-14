{
  pkgs,
  stdenv,
  python3,
  mstflint,
  mkUnpackScript,
  mlnx-ofed-src,
  mlnx-ethtool,
  ...
}:

stdenv.mkDerivation rec {
  pname = "mlnx-tools";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript pname;

  nativeBuildInputs = [ ];

  runtimeInputs = [
    python3
    mstflint
    mlnx-ethtool
  ];

  patchPhase = ''
    substituteInPlace sbin/* \
      --replace-warn '/bin/ls' 'ls' \
      --replace-warn '/bin/systemctl' 'systemctl' \
      --replace-warn '/sbin/sysctl' 'sysctl'

    substituteInPlace tsbin/* \
      --replace-warn '/bin/ls' 'ls' \
      --replace-warn '/bin/rm' 'rm' \
      --replace-warn '/usr/bin/bash' '/usr/bin/env bash' \
      --replace-warn '/bin/bash' 'bash' 
  '';

  enableParallelBuilding = true;

  installFlags = [ "DESTDIR=${placeholder "out"}" ];

  meta = with pkgs.lib; {
    description = "Mellanox mlnx-tools for managing adapters";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
