#!/bin/sh
# Verified basefix only. Use after official recovery, without running main.sh again.
set -eu
MOUNT_DIR="/mnt/lacie_sda9_fix"
[ -b /dev/sda9 ] || { echo "ERROR missing /dev/sda9"; cat /proc/partitions; exit 1; }
mkdir -p "$MOUNT_DIR"
mount -o rw /dev/sda9 "$MOUNT_DIR"
mkdir -p "$MOUNT_DIR/snaps/00/etc"

cat > "$MOUNT_DIR/snaps/00/etc/passwd" <<'EOF_PASSWD'
root:x:0:0:root:/root:/bin/sh
admin:x:1000:1000:admin:/home/admin:/bin/sh
nobody:x:65534:65534:nobody:/nonexistent:/bin/false
messagebus:x:81:81:dbus:/var/run/dbus:/bin/false
sshd:x:74:74:sshd:/var/empty/sshd:/bin/false
EOF_PASSWD
cat > "$MOUNT_DIR/snaps/00/etc/group" <<'EOF_GROUP'
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
EOF_GROUP
cat > "$MOUNT_DIR/snaps/00/etc/shadow" <<'EOF_SHADOW'
root:*:10933:0:99999:7:::
admin:*:10933:0:99999:7:::
nobody:*:10933:0:99999:7:::
messagebus:*:10933:0:99999:7:::
sshd:*:10933:0:99999:7:::
EOF_SHADOW
cat > "$MOUNT_DIR/snaps/00/etc/gshadow" <<'EOF_GSHADOW'
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
EOF_GSHADOW
cat > "$MOUNT_DIR/snaps/00/etc/fstab" <<'EOF_FSTAB'
# Restored minimal fstab for LaCie 5big Network 2
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
devpts /dev/pts devpts mode=0620,gid=5 0 0
tmpfs /dev/shm tmpfs defaults 0 0
EOF_FSTAB
chmod 0644 "$MOUNT_DIR/snaps/00/etc/passwd" "$MOUNT_DIR/snaps/00/etc/group" "$MOUNT_DIR/snaps/00/etc/fstab"
chmod 0600 "$MOUNT_DIR/snaps/00/etc/shadow" "$MOUNT_DIR/snaps/00/etc/gshadow"
ls -l "$MOUNT_DIR/snaps/00/etc/passwd" "$MOUNT_DIR/snaps/00/etc/group" "$MOUNT_DIR/snaps/00/etc/shadow" "$MOUNT_DIR/snaps/00/etc/gshadow" "$MOUNT_DIR/snaps/00/etc/fstab"
wc -l "$MOUNT_DIR/snaps/00/etc/passwd" "$MOUNT_DIR/snaps/00/etc/group" "$MOUNT_DIR/snaps/00/etc/shadow" "$MOUNT_DIR/snaps/00/etc/gshadow" "$MOUNT_DIR/snaps/00/etc/fstab"
sync
umount "$MOUNT_DIR"
sync
echo LACIE_BASEFIX_MANUAL_OK
