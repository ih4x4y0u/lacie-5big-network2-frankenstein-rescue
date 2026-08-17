# LaCie 5big Network 2 Frankenstein Rescue v2

Kit corregido tras prueba real de recovery.

La version v2 usa un flujo mas seguro.

```text
1 solo HDD limpio en bahia 1
rescue RAM por CLUNC
runner de recovery seguro
basefix manual verificado
primer arranque a Dashboard
luego se agregan los otros HDD desde Dashboard
```

## Flujo rapido probado

En el PC Linux de rescate.

```bash
sudo bash scripts/workstation/prepare-workstation.sh
sudo bash scripts/workstation/install-tftp-files.sh
```

Entrar a `Marvell>>`.

```bash
cd ~/clunc
sudo env PATH="$HOME/clunc/build:$PATH" ./clunc -v -m 00:D0:4B:8E:54:7F -i 192.168.1.250
```

En `Marvell>>`.

```text
setenv bootargs 'console=ttyS0,115200 static_addr=192.168.1.250 tftp_server=192.168.1.200 mode=telnet'
tftp 0x800000 uImage-lacie-rescue
bootm 0x800000
```

Entrar al rescue.

```bash
nc 192.168.1.250 23
```

En el prompt `#`.

```sh
cd /tmp
tftp -g -r lacie-one-disk-safe-recovery.sh 192.168.1.200
sh lacie-one-disk-safe-recovery.sh
```

Al final.

```sh
reboot -f
```

Comprobar.

```bash
sudo arp-scan --interface=enp1s0 192.168.1.0/24
ping -c 4 192.168.1.40
nc -vz -w 3 192.168.1.40 80
```

Dashboard.

```text
http://192.168.1.40/?locale=es
```

## Cambios v2

- Se documenta como flujo principal el recovery con 1 HDD.
- Se agrega `lacie-one-disk-safe-recovery.sh`.
- El runner detecta el fallo de refresco de particiones y relanza una vez el recovery oficial.
- El basefix ahora escribe y verifica `passwd`, `group`, `shadow`, `gshadow` y `fstab`.
- `install-tftp-files.sh` arregla permisos de directorios TFTP a `755` y ficheros a `644`.
- Se conserva el firmware oficial, GPL, rescue RAM, CLUNC Python y docs.

## Estructura clave

```text
firmware/tftp-ready/uImage-lacie-rescue
firmware/tftp-ready/description.xml
firmware/tftp-ready/repository/rootfs.tar.lzma
firmware/tftp-ready/repository/bootfs.tar.lzma
scripts/rescue/lacie-one-disk-safe-recovery.sh
scripts/rescue/lacie-basefix-manual-verified.sh
scripts/workstation/install-tftp-files.sh
docs/00_RECOVERY_PROBADO_1_HDD.md
```

## Licencia

Scripts y docs propios bajo MIT. Firmware y GPL mantienen origen y licencias de LaCie Seagate.
