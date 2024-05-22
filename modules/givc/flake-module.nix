# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{inputs, ...}: {
  flake.nixosModules = {
    givc-host.imports = [
      inputs.givc.nixosModules.host
      ./common.nix
      ./host.nix
    ];
    givc-adminvm.imports = [
      inputs.givc.nixosModules.admin
      inputs.givc.nixosModules.sysvm
      ./common.nix
      ./adminvm.nix
    ];
  };
  flake.overlays = {
    givc-app = inputs.givc.overlays.default;
  };
}
