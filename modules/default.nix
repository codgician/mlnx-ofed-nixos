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

      fwctl = {
        enable = lib.mkEnableOption "fwctl kernel module for firmware control";

        package = lib.mkOption {
          type = types.package;
          default = config.boot.kernelPackages.fwctl;
          defaultText = "config.boot.kernelPackages.fwctl";
          example = lib.literalExpressionliteralExpression "config.boot.kernelPackages.fwctl";
          description = ''
            Defines which package to use for kernel module fwctl.
          '';
        };
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
          default = config.boot.kernelPackages.nfsrdma;
          defaultText = "config.boot.kernelPackages.nfsrdma";
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
    };
  };

  config = lib.mkIf cfg.enable {
    # Add kernel modules
    boot.extraModulePackages =
      [ cfg.package ]
      ++ lib.optional cfg.fwctl.enable cfg.fwctl.package
      ++ lib.optional cfg.kernel-mft.enable cfg.kernel-mft.package
      ++ lib.optional cfg.nfsrdma.enable cfg.nfsrdma.package
      ++ lib.optional cfg.nvme.enable cfg.nvme.package;

    # Install mstflint
    environment.systemPackages = with pkgs; [ mstflint ];
  };
}
