#!/bin/sh
# LaCie 5big Network 2 V2 safe one disk recovery runner
# Runs official recovery on one HDD, retries once after partition refresh, then applies basefix.
set -u

TFTP_SERVER="${1:-192.168.1.200}"
MOUNT_DIR="/mnt/lacie_sda9_fix"
LOG1="/tmp/lacie-main-pass1.log"
LOG2="/tmp/lacie-main-pass2.log"

fail() {
  echo "ERROR: $*"
  exit 1
}

count_sd_disks() {
  local n=0 b
  for b in /sys/block/sd?; do
    [ -e "$b" ] || continue
    n=$((n + 1))
  done
  echo "$n"
}

wait_partitions() {
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    [ -b /dev/sda8 ] && [ -b /dev/sda9 ] && [ -b /dev/sda10 ] && return 0
    sleep 2
  done
  return 1
}

stop_mdadm() {
  mdadm --stop /dev/md9 2>/dev/null || true
  mdadm --stop /dev/md8 2>/dev/null || true
  mdadm --stop /dev/md7 2>/dev/null || true
}

write_basefix() {
  [ -b /dev/sda9 ] || fail "missing /dev/sda9"
  mkdir -p "$MOUNT_DIR"
  if ! mount | grep -q " $MOUNT_DIR "; then
    mount -o rw /dev/sda9 "$MOUNT_DIR" || fail "cannot mount /dev/sda9"
  fi
  mount -o remount,rw "$MOUNT_DIR" 2>/dev/null || true
  mkdir -p "$MOUNT_DIR/snaps/00/etc"

  cat > "$MOUNT_DIR/snaps/00/etc/passwd" <<'PASSWD'
root:x:0:0:root:/root:/bin/sh
admin:x:1000:1000:admin:/home/admin:/bin/sh
nobody:x:65534:65534:nobody:/nonexistent:/bin/false
messagebus:x:81:81:dbus:/var/run/dbus:/bin/false
sshd:x:74:74:sshd:/var/empty/sshd:/bin/false
PASSWD

  cat > "$MOUNT_DIR/snaps/00/etc/group" <<'GROUP'
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:
fax:x:21:
voice:x:22:
cdrom:x:24:
floppy:x:25:
tape:x:26:
sudo:x:27:
audio:x:29:
dip:x:30:
www-data:x:33:
backup:x:34:
operator:x:37:
list:x:38:
irc:x:39:
src:x:40:
gnats:x:41:
shadow:x:42:
utmp:x:43:
video:x:44:
sasl:x:45:
plugdev:x:46:
staff:x:50:
games:x:60:
users:x:100:
nogroup:x:65534:
admin:x:1000:
messagebus:x:81:
sshd:x:74:
GROUP

  cat > "$MOUNT_DIR/snaps/00/etc/shadow" <<'SHADOW'
root:*:10933:0:99999:7:::
admin:*:10933:0:99999:7:::
nobody:*:10933:0:99999:7:::
messagebus:*:10933:0:99999:7:::
sshd:*:10933:0:99999:7:::
SHADOW

  cat > "$MOUNT_DIR/snaps/00/etc/gshadow" <<'GSHADOW'
root:*::
daemon:*::
bin:*::
sys:*::
adm:*::
tty:*::
disk:*::
lp:*::
mail:*::
news:*::
uucp:*::
man:*::
proxy:*::
kmem:*::
dialout:*::
fax:*::
voice:*::
cdrom:*::
floppy:*::
tape:*::
sudo:*::
audio:*::
dip:*::
www-data:*::
backup:*::
operator:*::
list:*::
irc:*::
src:*::
gnats:*::
shadow:*::
utmp:*::
video:*::
sasl:*::
plugdev:*::
staff:*::
games:*::
users:*::
nogroup:*::
admin:*::
messagebus:*::
sshd:*::
GSHADOW

  cat > "$MOUNT_DIR/snaps/00/etc/fstab" <<'FSTAB'
# Restored minimal fstab for LaCie 5big Network 2
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
devpts /dev/pts devpts mode=0620,gid=5 0 0
tmpfs /dev/shm tmpfs defaults 0 0
FSTAB

  chmod 0644 "$MOUNT_DIR/snaps/00/etc/passwd" "$MOUNT_DIR/snaps/00/etc/group" "$MOUNT_DIR/snaps/00/etc/fstab"
  chmod 0600 "$MOUNT_DIR/snaps/00/etc/shadow" "$MOUNT_DIR/snaps/00/etc/gshadow"

  echo "VERIFY_BASEFIX_FILES"
  ls -l "$MOUNT_DIR/snaps/00/etc/passwd" "$MOUNT_DIR/snaps/00/etc/group" "$MOUNT_DIR/snaps/00/etc/shadow" "$MOUNT_DIR/snaps/00/etc/gshadow" "$MOUNT_DIR/snaps/00/etc/fstab"
  wc -l "$MOUNT_DIR/snaps/00/etc/passwd" "$MOUNT_DIR/snaps/00/etc/group" "$MOUNT_DIR/snaps/00/etc/shadow" "$MOUNT_DIR/snaps/00/etc/gshadow" "$MOUNT_DIR/snaps/00/etc/fstab"
  sync
  umount "$MOUNT_DIR" || fail "cannot umount $MOUNT_DIR"
  sync
  echo "LACIE_BASEFIX_MANUAL_OK"
}

echo "LACIE_ONE_DISK_SAFE_RECOVERY_START"
echo "Expected setup: one clean HDD in bay 1 only. Other bays empty."
echo "Disk count: $(count_sd_disks)"
[ "$(count_sd_disks)" = "1" ] || fail "this safe runner requires exactly one sd disk"
[ -b /dev/sda ] || fail "missing /dev/sda"
cat /proc/partitions

echo "PASS1_OFFICIAL_RECOVERY_START"
/nas-rescue/main.sh 2>&1 | tee "$LOG1"
echo "PASS1_OFFICIAL_RECOVERY_END"

wait_partitions || true
cat /proc/partitions

if grep -q "create aborted\|Cannot open /dev/sda8\|Cannot open /dev/sda9" "$LOG1" 2>/dev/null; then
  echo "PASS1_NEEDS_RETRY_AFTER_PARTITION_REFRESH"
  stop_mdadm
  /nas-rescue/main.sh 2>&1 | tee "$LOG2"
  echo "PASS2_OFFICIAL_RECOVERY_END"
else
  echo "PASS1_NO_ABORT_DETECTED"
fi

wait_partitions || fail "sda8/sda9/sda10 not visible after recovery"
stop_mdadm
write_basefix

echo "LACIE_ONE_DISK_SAFE_RECOVERY_OK"
echo "Now run: reboot -f"
