#!/bin/sh
set -eu

echo '--- uname'
uname -a || true

echo '--- partitions'
cat /proc/partitions || true

echo '--- mdstat'
cat /proc/mdstat || true

echo '--- mounts'
mount || true

echo '--- block devices by fdisk'
fdisk -l 2>/dev/null || true
