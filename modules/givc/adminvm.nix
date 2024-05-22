# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  ...
}: let
  cfg = config.ghaf.givc.adminvm;
in
  with lib; {
    options.ghaf.givc.adminvm = {
      enable = mkOption {
        description = "Enable adminvm givc module.";
        type = types.bool;
        default = true;
      };
    };

    config = mkIf cfg.enable {
      givc.admin = {
        enable = true;
        inherit (config.ghaf.givc.adminConfig) addr;
        inherit (config.ghaf.givc.adminConfig) port;
        inherit (config.ghaf.givc.adminConfig) protocol;
        services = [
          "givc-host.service"
          "givc-admin-vm.service"
        ];
        tls.enable = false;
        # tls = {
        #   ca-cert-path = "my/ca/cert/path";
        #   cert-path = "my/cert/path";
        #   key-path = "my/key/path";
        # };
      };
    };
  }
