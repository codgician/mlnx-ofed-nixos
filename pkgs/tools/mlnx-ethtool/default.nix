{
  pkgs,
  ethtool,
  mkUnpackScript,
  mlnx-ofed-src,
  ...
}:

ethtool.overrideAttrs (oldAttrs: rec {
  pname = "mlnx-ethtool";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript pname;

  meta =
    with pkgs.lib;
    oldAttrs
    // {
      description = "(Mellanox variant) ${oldAttrs.meta.description}";
      maintainers = with maintainers; [ codgician ];
    };
})
