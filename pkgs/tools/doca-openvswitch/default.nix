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

  unpackPhase = mkUnpackScript "openvswitch";

  # The DOCA Open vSwitch source ships pre-generated configure, no need for boot.sh
  preConfigure = "";

  postPatch = (oldAttrs.postPatch or "") + ''
    # NVIDIA's source archive omits the Debian installation guide.
    sed -i '\|Documentation/intro/install/debian\.rst|d' Makefile.in
    sed -i '/^   debian$/d' Documentation/intro/install/index.rst
    sed -i '\|^- Follow the instructions in :doc:`/intro/install/debian`|,+2d' \
      Documentation/howto/vtep.rst
    patchShebangs utilities/git-desc.sh
  '';

  meta = oldAttrs.meta // {
    description = "(DOCA variant) ${oldAttrs.meta.description}";
    maintainers = with lib.maintainers; [ codgician ];
  };
})
