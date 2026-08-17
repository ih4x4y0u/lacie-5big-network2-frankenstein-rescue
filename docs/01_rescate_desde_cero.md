# Rescate desde cero v2

## Preparacion fisica

- LaCie apagada.
- Solo 1 HDD limpio en bahia 1.
- Bahias 2 a 5 vacias.
- Cable Ethernet al PC Linux rescue.
- PC rescue con IP `192.168.1.200/24` en `enp1s0`.
- TFTP activo en `/srv/tftp`.

## Preparar PC rescue

```bash
cd ~/lacie-5big-network2-frankenstein-rescue-v2-one-disk-safe-20260817
sudo bash scripts/workstation/prepare-workstation.sh
sudo bash scripts/workstation/install-tftp-files.sh
```

## Capturar Marvell

```bash
cd ~/clunc
sudo env PATH="$HOME/clunc/build:$PATH" ./clunc -v -m 00:D0:4B:8E:54:7F -i 192.168.1.250
```

Encender la LaCie y esperar `Marvell>>`.

## Arrancar rescue RAM

```text
setenv bootargs 'console=ttyS0,115200 static_addr=192.168.1.250 tftp_server=192.168.1.200 mode=telnet'
tftp 0x800000 uImage-lacie-rescue
bootm 0x800000
```

En otra terminal.

```bash
nc 192.168.1.250 23
```

## Recovery seguro

En el prompt `#`.

```sh
cd /tmp
tftp -g -r lacie-one-disk-safe-recovery.sh 192.168.1.200
sh lacie-one-disk-safe-recovery.sh
```

El script hace.

- Verifica que solo hay un disco `sd`.
- Ejecuta `/nas-rescue/main.sh`.
- Si detecta `create aborted` por `/dev/sda8`, para `md7/md8/md9` y relanza una vez.
- Espera `sda8`, `sda9`, `sda10`.
- Monta `sda9`.
- Escribe `passwd`, `group`, `shadow`, `gshadow`, `fstab`.
- Verifica tamaño y lineas.
- Desmonta.

## Reinicio

```sh
reboot -f
```

## Prueba red

```bash
sudo arp-scan --interface=enp1s0 192.168.1.0/24
ping -c 4 192.168.1.40
nc -vz -w 3 192.168.1.40 80
```

## Dashboard

```text
http://192.168.1.40/?locale=es
```

## Discos restantes

Tras Dashboard operativo, apagar desde interfaz o interruptor, añadir los otros HDD y crear RAID desde Dashboard.
