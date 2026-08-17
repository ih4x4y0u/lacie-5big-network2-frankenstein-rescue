# Recovery probado con 1 HDD

Este flujo nace de la prueba viva del 17 de agosto de 2026.

Resultado probado.

```text
LaCie 5big Network 2 V2
MAC 00:D0:4B:8E:54:7F
PC rescue 192.168.1.200
Rescue RAM 192.168.1.250
Arranque normal final 192.168.1.40
Firmware 2.2.12.3
```

## Regla principal

Usar solo 1 HDD limpio en bahia 1 para recuperar el firmware.

Bahias 2, 3, 4 y 5 vacias durante recovery.

Tras Dashboard operativo, meter el resto de discos y crear RAID desde la interfaz LaCie.

## Por que esta version cambia el flujo

Con 5 HDD a la vez, el recovery oficial crea particiones y arrays, pero el arranque final puede quedarse sin red.

Con 1 HDD, el recovery tambien puede fallar la primera pasada con.

```text
mdadm: Cannot open /dev/sda8: No such file or directory
mdadm: create aborted
```

Ese fallo viene de refresco tardio de particiones. Justo despues, `sda8`, `sda9` y `sda10` ya existen.

La solucion probada fue.

```sh
mdadm --stop /dev/md7 2>/dev/null
/nas-rescue/main.sh
```

La segunda pasada termino, paro `md7`, `md8` y `md9`, y dejo el sistema en `sda9`.

## Comando recomendado dentro de rescue

Despues de entrar al prompt `#`, bajar el runner.

```sh
cd /tmp
tftp -g -r lacie-one-disk-safe-recovery.sh 192.168.1.200
sh lacie-one-disk-safe-recovery.sh
```

Al terminar debe mostrar.

```text
LACIE_BASEFIX_MANUAL_OK
LACIE_ONE_DISK_SAFE_RECOVERY_OK
Now run: reboot -f
```

Despues.

```sh
reboot -f
```

## Comprobacion desde el PC Linux

```bash
sudo arp-scan --interface=enp1s0 192.168.1.0/24
ping -c 4 192.168.1.40
nc -vz -w 3 192.168.1.40 80
```

Exito esperado.

```text
192.168.1.40 00:d0:4b:8e:54:7f
4 received, 0% packet loss
Connection to 192.168.1.40 80 port succeeded
```

Dashboard.

```text
http://192.168.1.40/?locale=es
```

## No hacer durante esta fase

No meter los otros discos.
No repetir recovery con 5 discos.
No apagar durante escritura de particiones.
No usar HTTPS para el Dashboard inicial.
