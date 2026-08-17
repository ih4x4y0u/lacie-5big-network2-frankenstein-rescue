#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TFTP_DIR="${1:-/srv/tftp}"

sudo mkdir -p "$TFTP_DIR"
sudo cp -a "$ROOT_DIR/firmware/tftp-ready/." "$TFTP_DIR/"
sudo cp -a "$ROOT_DIR/scripts/rescue/lacie-basefix-minimal.sh" "$TFTP_DIR/"
sudo cp -a "$ROOT_DIR/scripts/rescue/lacie-basefix-manual-verified.sh" "$TFTP_DIR/"
sudo cp -a "$ROOT_DIR/scripts/rescue/lacie-one-disk-safe-recovery.sh" "$TFTP_DIR/"
sudo cp -a "$ROOT_DIR/scripts/rescue/lacie-disk-inspect.sh" "$TFTP_DIR/"
sudo find "$TFTP_DIR" -type d -exec chmod 755 {} \;
sudo find "$TFTP_DIR" -type f -exec chmod 644 {} \;

echo TFTP_FILES_INSTALLED "$TFTP_DIR"
find "$TFTP_DIR" -maxdepth 3 -type f \( -name 'uImage-lacie-rescue' -o -name 'description.xml' -o -name 'rootfs.tar.lzma' -o -name 'bootfs.tar.lzma' -o -name 'lacie-one-disk-safe-recovery.sh' -o -name 'lacie-basefix-minimal.sh' \) -ls
