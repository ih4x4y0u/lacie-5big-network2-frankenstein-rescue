#!/usr/bin/env bash
set -euo pipefail

if command -v apt-get >/dev/null 2>&1; then
  apt-get update
  apt-get install -y tftpd-hpa tftp-hpa netcat-openbsd smbclient python3 coreutils unzip tar
fi

mkdir -p /srv/tftp
chmod 755 /srv/tftp

if command -v systemctl >/dev/null 2>&1; then
  systemctl enable --now tftpd-hpa || true
fi

echo WORKSTATION_READY
