{
  pkgs,
  stdenv,
  ethtool,
  mkUnpackScript,
  mlnx-ofed-src,
  ...
}:

ethtool.overrideAttrs (oldAttrs: rec {
  pname = "mlnx-ethtool";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript pname;

  meta = with pkgs.lib; {
    description = "Mellanox ethtool utility";
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
})
