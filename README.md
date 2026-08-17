# LaCie 5big Network 2 Frankenstein Rescue

Guia practica para revivir una LaCie 5big Network 2 que no arranca, no muestra Dashboard o solo permite entrar por U-Boot/Marvell mediante CLUNC.

Este repositorio incluye firmware original, ficheros TFTP, scripts de rescate y una receta probada en una recuperacion real.

## Que problema resuelve

La LaCie 5big Network 2 puede quedar en este estado:

```text
No entra al Dashboard
No responde por SMB
No arranca normal desde disco
Solo permite acceso a Marvell U-Boot por CLUNC
El recovery oficial falla a medias por refresco de particiones
El sistema instalado arranca sin passwd, group, shadow, gshadow o fstab
```

La solucion probada es:

```text
Arrancar rescue RAM por TFTP
Instalar el sistema oficial en 1 solo HDD limpio
Aplicar basefix verificado antes del primer arranque normal
Entrar al Dashboard
Anadir los otros discos desde Dashboard
```

## Aviso importante

Este procedimiento borra discos. Usalo solo con discos sin datos importantes.

No metas los cinco HDD al principio. El flujo probado usa solo un disco en la bahia 1. Despues del primer arranque correcto, los discos restantes se agregan desde Dashboard.

## Hardware necesario

```text
LaCie 5big Network 2
1 HDD limpio para la bahia 1
PC Linux de rescate con Ethernet
Cable Ethernet entre PC Linux y red donde esta la LaCie
Router o switch en la red 192.168.1.0/24
Mac o PC para abrir GitHub y Dashboard
```

Ejemplo probado:

```text
PC Linux de rescate: workstation-backup
Interfaz Ethernet: enp1s0
IP PC rescate: 192.168.1.200/24
IP rescue RAM LaCie: 192.168.1.250
IP normal LaCie tras arrancar: 192.168.1.40
MAC LaCie usada por CLUNC: 00:D0:4B:8E:54:7F
```

Adapta IP e interfaz a tu red si tu entorno es distinto.

## Estructura del pack

```text
commands/                         Comandos cortos para U-Boot
firmware/tftp-ready/              Ficheros que debe servir TFTP
firmware/original/                Firmware original usado como base
firmware/gpl_code/                GPL dividido en partes
scripts/workstation/              Scripts para preparar el PC Linux
scripts/rescue/                   Scripts que se lanzan dentro del rescue RAM
docs/                             Documentacion ampliada
README.md                         Esta guia
MANIFEST.sha256                   Verificacion de integridad
```

## Paso 1. Descargar y verificar el repositorio

En el Mac o PC:

```bash
git clone https://github.com/ih4x4y0u/lacie-5big-network2-frankenstein-rescue.git
cd lacie-5big-network2-frankenstein-rescue
shasum -a 256 -c MANIFEST.sha256
```

Debe terminar con todos los ficheros en `OK`.

## Paso 2. Copiar el pack al PC Linux de rescate

Ejemplo hacia `workstation-backup`:

```bash
scp -r ~/Downloads/lacie-5big-network2-frankenstein-rescue ih4x4y0u@192.168.2.60:~/
```

Si tu usuario Linux es otro, cambia `ih4x4y0u` por tu usuario real.

En el PC Linux de rescate:

```bash
cd ~/lacie-5big-network2-frankenstein-rescue
shasum -a 256 -c MANIFEST.sha256
```

## Paso 3. Preparar el PC Linux de rescate

En el PC Linux:

```bash
cd ~/lacie-5big-network2-frankenstein-rescue
sudo bash scripts/workstation/prepare-workstation.sh
sudo bash scripts/workstation/install-tftp-files.sh
```

Verifica que TFTP tiene los ficheros:

```bash
ls -l /srv/tftp/uImage-lacie-rescue
ls -l /srv/tftp/description.xml
ls -l /srv/tftp/repository/rootfs.tar.lzma
ls -l /srv/tftp/repository/bootfs.tar.lzma
ls -l /srv/tftp/lacie-one-disk-safe-recovery.sh
```

Comprueba permisos:

```bash
ls -ld /srv/tftp /srv/tftp/repository
```

Debe verse algo parecido a:

```text
drwxr-xr-x /srv/tftp
drwxr-xr-x /srv/tftp/repository
```

## Paso 4. Preparar la LaCie con un solo disco

Apaga la LaCie.

```text
1. Desconecta corriente.
2. Saca todos los discos.
3. Mete 1 solo HDD limpio en bahia 1.
4. Deja las bahias 2, 3, 4 y 5 vacias.
5. Conecta corriente, pero no enciendas aun.
```

## Paso 5. Entrar a Marvell U-Boot por CLUNC

En el PC Linux de rescate, abre una terminal:

```bash
cd ~/clunc
sudo env PATH="$HOME/clunc/build:$PATH" ./clunc -v -m 00:D0:4B:8E:54:7F -i 192.168.1.250
```

Enciende la LaCie.

Espera el prompt:

```text
Marvell>>
```

Si no sale tras unos segundos, pulsa Enter una vez.

## Paso 6. Arrancar rescue RAM por TFTP

En `Marvell>>` pega:

```text
setenv bootargs 'console=ttyS0,115200 static_addr=192.168.1.250 tftp_server=192.168.1.200 mode=telnet'
tftp 0x800000 uImage-lacie-rescue
bootm 0x800000
```

Espera a que cargue el rescue.

## Paso 7. Entrar al rescue RAM

En otra terminal del PC Linux:

```bash
nc 192.168.1.250 23
```

Si ves caracteres raros, pulsa Enter una vez.

Debes llegar a:

```text
#
```

## Paso 8. Confirmar que solo hay un HDD

Dentro del rescue:

```sh
cat /proc/partitions
```

Debe salir un disco tipo:

```text
sda
```

No deben salir `sdb`, `sdc`, `sdd` ni `sde` en esta fase.

## Paso 9. Lanzar el recovery seguro de 1 HDD

Dentro del rescue:

```sh
cd /tmp
tftp -g -r lacie-one-disk-safe-recovery.sh 192.168.1.200
sh lacie-one-disk-safe-recovery.sh
```

El script hace esto:

```text
Ejecuta /nas-rescue/main.sh
Detecta si el fallo fue por refresco tardio de sda8
Para md7 si hace falta
Relanza una segunda pasada controlada
Monta /dev/sda9
Escribe passwd, group, shadow, gshadow y fstab
Verifica los cinco ficheros
Hace sync
```

Durante el proceso se pueden ver muchas lineas de este tipo:

```text
connect_to_notifier: connect failed: Connection refused
ERROR: send_event_notification failed
Error when sending notification. Continue...
```

Esos avisos son normales en rescue RAM. El fallo real seria algo como:

```text
mdadm: create aborted
```

Si el script termina bien, debe mostrar:

```text
LACIE_ONE_DISK_SAFE_RECOVERY_OK
```

## Paso 10. Reiniciar

Dentro del rescue:

```sh
sync
reboot -f
```

Espera 4 o 5 minutos.

## Paso 11. Comprobar red y Dashboard

En el PC Linux:

```bash
sudo arp-scan --interface=enp1s0 192.168.1.0/24
ping -c 4 192.168.1.40
nc -vz -w 3 192.168.1.40 80
```

Resultado esperado:

```text
192.168.1.40  00:d0:4b:8e:54:7f
ping OK
port 80 succeeded
```

Abre en navegador:

```text
http://192.168.1.40/?locale=es
```

No uses HTTPS. Este firmware es antiguo y puede fallar con TLS moderno.

## Paso 12. Primer arranque en Dashboard

En Dashboard:

```text
1. Haz el setup inicial.
2. Configura usuario admin.
3. Revisa informacion de unidad.
4. Crea un recurso compartido simple, por ejemplo Public.
5. Comprueba acceso SMB si lo necesitas.
```

Prueba SMB desde Linux:

```bash
smbclient -L //192.168.1.40 -U admin -m NT1 --option='client min protocol=NT1'
```

## Paso 13. Agregar los otros discos

Solo despues de confirmar Dashboard y sistema base:

```text
1. Apaga desde Dashboard si es posible.
2. Inserta los otros HDD.
3. Enciende.
4. Entra al Dashboard.
5. Crea o reconstruye RAID desde la interfaz.
6. Espera a que termine la sincronizacion.
```

No cortes corriente durante sincronizacion RAID.

## Errores conocidos

### `mdadm: Cannot open /dev/sda8`

Puede pasar en la primera pasada porque el kernel viejo no refresca la tabla de particiones a tiempo.

El runner v2 lo gestiona relanzando una segunda pasada si `sda8`, `sda9` y `sda10` ya existen.

### Dashboard abre pero muestra 0B o falla DBus

Suele indicar falta de estos ficheros en el overlay:

```text
/etc/passwd
/etc/group
/etc/shadow
/etc/gshadow
/etc/fstab
```

El basefix v2 los escribe en:

```text
/mnt/check/snaps/00/etc/
```

### No sale la LaCie en red

Busca la MAC:

```bash
sudo arp-scan --interface=enp1s0 192.168.1.0/24 | grep -i '00:d0:4b'
```

Si no sale, vuelve a rescue RAM y revisa `/dev/sda9`.

## Comandos manuales de emergencia

Montar sistema instalado desde rescue:

```sh
mkdir -p /mnt/check
mount -o rw /dev/sda9 /mnt/check
ls -la /mnt/check/snaps/00/etc
```

Verificar ficheros clave:

```sh
ls -l /mnt/check/snaps/00/etc/passwd /mnt/check/snaps/00/etc/group /mnt/check/snaps/00/etc/shadow /mnt/check/snaps/00/etc/gshadow /mnt/check/snaps/00/etc/fstab
```

## Archivos clave

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

## Estado probado

Este flujo fue validado con:

```text
LaCie 5big Network 2
Firmware capsule 2.2.12.3
Recovery RAM por CLUNC
1 HDD HGST 4 TB en bahia 1
IP rescue 192.168.1.250
IP normal 192.168.1.40
Dashboard por HTTP funcionando
```

## Licencia

Scripts y documentacion propia bajo MIT.

Firmware, capsule, GPL y componentes LaCie Seagate mantienen su origen y sus licencias correspondientes.
