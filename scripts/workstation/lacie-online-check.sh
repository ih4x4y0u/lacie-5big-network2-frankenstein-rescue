#!/usr/bin/env bash
set -euo pipefail

NAS_IP="${1:-192.168.1.40}"
USER_NAME="${2:-admin}"
SHARE_NAME="${3:-Public}"
TMP1="/tmp/lacie-online-check-$$.txt"
TMP2="/tmp/lacie-online-check-back-$$.txt"

echo "CHECK ping $NAS_IP"
ping -c 4 "$NAS_IP"

echo "CHECK ports"
for p in 80 139 445 548; do
  nc -vz -w 3 "$NAS_IP" "$p" || true
done

echo "CHECK http"
curl -fsS "http://$NAS_IP/" >/dev/null

echo "CHECK smb list"
smbclient -L "//$NAS_IP" -U "$USER_NAME" -m NT1 --option='client min protocol=NT1'

echo "lacie check ok" > "$TMP1"
echo "CHECK smb write read"
smbclient "//$NAS_IP/$SHARE_NAME" -U "$USER_NAME" -m NT1 --option='client min protocol=NT1' -c "put $TMP1 lacie-online-check.txt; get lacie-online-check.txt $TMP2; dir"

grep -q "lacie check ok" "$TMP2"
rm -f "$TMP1" "$TMP2"
echo LACIE_ONLINE_CHECK_OK
