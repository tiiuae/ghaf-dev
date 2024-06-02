# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  pkgs,
  lib,
  config,
  ...
}: let
  xdgPdfPort = 1200;
in {
  name = "chromium";
  packages = let
    # PDF XDG handler is executed when the user opens a PDF file in the browser
    # The xdgopenpdf script sends a command to the guivm with the file path over TCP connection
    xdgPdfItem = pkgs.makeDesktopItem {
      name = "ghaf-pdf";
      desktopName = "Ghaf PDF handler";
      exec = "${xdgOpenPdf}/bin/xdgopenpdf %u";
      mimeTypes = ["application/pdf"];
    };
    xdgOpenPdf = pkgs.writeShellScriptBin "xdgopenpdf" ''
      filepath=$(realpath "$1")
      echo "Opening $filepath" | systemd-cat -p info
      echo $filepath | ${pkgs.netcat}/bin/nc -N gui-vm ${toString xdgPdfPort}
    '';
  in [
    pkgs.chromium
    pkgs.pulseaudio
    pkgs.xdg-utils
    xdgPdfItem
    xdgOpenPdf
  ];
  # TODO create a repository of mac addresses to avoid conflicts
  macAddress = "02:00:00:03:05:01";
  ramMb = 3072;
  cores = 4;
  extraModules = [
    {
      imports = [../programs/chromium.nix];
      # Enable pulseaudio for Chromium VM
      security.rtkit.enable = true;
      sound.enable = true;
      users.extraUsers.ghaf.extraGroups = ["audio" "video"];

      hardware.pulseaudio = {
        enable = true;
        extraConfig = ''
          load-module module-tunnel-sink sink_name=chromium-speaker server=audio-vm:4713 format=s16le channels=2 rate=48000
          load-module module-tunnel-source source_name=chromium-mic server=audio-vm:4713 format=s16le channels=1 rate=48000

          # Set sink and source default max volume to about 90% (0-65536)
          set-sink-volume chromium-speaker 60000
          set-source-volume chromium-mic 60000
        '';
      };

      time.timeZone = config.time.timeZone;

      microvm.qemu.extraArgs = lib.optionals config.ghaf.hardware.usb.internal.enable config.ghaf.hardware.usb.internal.qemuExtraArgs.webcam;
      ghaf.givc.appvm = {
        enable = true;
        name = lib.mkForce "chromium-vm";
        applications = lib.mkForce ''          {
                    "chromium": "run-waypipe chromium --enable-features=UseOzonePlatform --ozone-platform=wayland",
                    "chromium-ids": "run-waypipe chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --user-data-dir=/home/${config.ghaf.users.accounts.user}/.config/chromium/Default --test-type --ignore-certificate-errors-spki-list=Bq49YmAq1CG6FuBzp8nsyRXumW7Dmkp7QQ/F82azxGU="
                  }'';
      };
      microvm.devices = [];

      ghaf.programs.chromium.enable = true;

      # Set default PDF XDG handler
      xdg.mime.defaultApplications."application/pdf" = "ghaf-pdf.desktop";
    }
  ];
  borderColor = "#630505";
  vtpm.enable = true;
}
