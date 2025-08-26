{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.hardware.mlnx-ofed;
in
{
  imports = [
    (lib.mkRemovedOptionModule [
      "hardware"
      "mlnx-ofed"
      "fwctl"
      "enable"
    ] "fwctl kernel module is removed since mlnx-ofed 25.07")
    (lib.mkRemovedOptionModule [
      "hardware"
      "mlnx-ofed"
      "fwctl"
      "package"
    ] "fwctl kernel module is removed since mlnx-ofed 25.07")
  ];

  options = {
    hardware.mlnx-ofed = {
      enable = lib.mkEnableOption "MLNX-OFED drivers";

      package = lib.mkOption {
        type = types.package;
        default = config.boot.kernelPackages.mlnx-ofed-kernel;
        defaultText = "config.boot.kernelPackages.mlnx-ofed-kernel";
        example = lib.literalExpressionliteralExpression "config.boot.kernelPackages.mlnx-ofed-kernel";
        description = ''
          Defines which package to use for kernel module mlnx-ofed-kernel.
        '';
      };

      kernel-mft = {
        enable = lib.mkEnableOption "kernel-mft kernel module for Mellanox firmware tools";

        package = lib.mkOption {
          type = types.package;
          default = config.boot.kernelPackages.kernel-mft;
          defaultText = "config.boot.kernelPackages.kernel-mft";
          example = lib.literalExpressionliteralExpression "config.boot.kernelPackages.kernel-mft";
          description = ''
            Defines which package to use for kernel module kernel-mft.
          '';
        };
      };

      nfsrdma = {
        enable = lib.mkEnableOption "nfsrdma kernel module for NFS over RDMA";

        package = lib.mkOption {
          type = types.package;
          default = config.boot.kernelPackages.mlnx-nfsrdma;
          defaultText = "config.boot.kernelPackages.mlnx-nfsrdma";
          example = lib.literalExpressionliteralExpression "config.boot.kernelPackages.nfsrdma";
          description = ''
            Defines which package to use for kernel module nfsrdma.
          '';
        };
      };

      nvme = {
        enable = lib.mkEnableOption "mlnx-nvme kernel module for nvme over fabrics";

        package = lib.mkOption {
          type = types.package;
          default = config.boot.kernelPackages.mlnx-nvme;
          defaultText = "config.boot.kernelPackages.mlnx-nvme";
          example = lib.literalExpressionliteralExpression "config.boot.kernelPackages.mlnx-nvme";
          description = ''
            Defines which package to use for kernel module mlnx-nvme.
          '';
        };
      };

      virtiofs = {
        enable = lib.mkEnableOption "DOCA SNAP virtiofs kernel module from Mellanox";

        package = lib.mkOption {
          type = types.package;
          default = config.boot.kernelPackages.mlnx-nvme;
          defaultText = "config.boot.kernelPackages.virtiofs";
          example = lib.literalExpressionliteralExpression "config.boot.kernelPackages.virtiofs";
          description = ''
            Defines which package to use for kernel module DOCA SNAP virtiofs.
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Add kernel modules
    boot.extraModulePackages = [
      cfg.package
    ]
    ++ lib.optional cfg.kernel-mft.enable cfg.kernel-mft.package
    ++ lib.optional cfg.nfsrdma.enable cfg.nfsrdma.package
    ++ lib.optional cfg.nvme.enable cfg.nvme.package
    ++ lib.optional cfg.virtiofs.enable cfg.virtiofs.package;
  };
}
