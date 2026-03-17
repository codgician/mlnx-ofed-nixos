{
  lib,
  openvswitch,
  mkUnpackScript,
  mlnx-ofed-src,
  ...
}:

openvswitch.overrideAttrs (oldAttrs: {
  pname = "doca-openvswitch";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "doca-openvswitch";

  # doca-openvswitch source ships pre-generated configure, no need for boot.sh
  preConfigure = "";

  meta = oldAttrs.meta // {
    description = "(DOCA variant) ${oldAttrs.meta.description}";
    maintainers = with lib.maintainers; [ codgician ];
  };
})
