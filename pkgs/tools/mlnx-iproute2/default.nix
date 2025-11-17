{
  lib,
  fetchurl,
  iproute2,
  mkUnpackScript,
  mlnx-ofed-src,
  ...
}:

iproute2.overrideAttrs (oldAttrs: rec {
  pname = "mlnx-iproute2";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript pname;

  patches = [
    (fetchurl {
      name = "musl-endian.patch";
      url = "https://lore.kernel.org/netdev/20240712191209.31324-1-contact@hacktivis.me/raw";
      hash = "sha256-MX+P+PSEh6XlhoWgzZEBlOV9aXhJNd20Gi0fJCcSZ5E=";
    })
    (fetchurl {
      name = "musl-basename.patch";
      url = "https://lore.kernel.org/netdev/20240804161054.942439-1-dilfridge@gentoo.org/raw";
      hash = "sha256-47obv6mIn/HO47lt47slpTAFDxiQ3U/voHKzIiIGCTM=";
    })
  ];

  meta =
    with lib;
    oldAttrs.meta
    // {
      description = "(Mellanox variant) ${oldAttrs.meta.description}";
      maintainers = with maintainers; [ codgician ];
    };
})
