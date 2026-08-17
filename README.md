# LaCie 5big Network 2 Frankenstein Rescue

Este repositorio sirve para recuperar una **LaCie 5big Network 2** que parece muerta desde red.

El caso practico que cubre es este:

```text
La NAS enciende, pero no responde en la red.
No sale en LaCie Network Assistant.
No responde a ping.
No abre Dashboard en el navegador.
No hace recovery desde LaCie Network Assistant.
No se puede entrar por SMB.
No se puede configurar desde la herramienta oficial.
```

En ese estado, el problema no es que falte una carpeta compartida o que el PC no la encuentre. El sistema interno de la NAS no esta arrancando bien desde los discos. La forma de recuperarla es arrancar un sistema temporal en RAM desde red, reinstalar el sistema oficial en un disco limpio y despues entrar al Dashboard para terminar la configuracion.

La receta probada usa este orden:

```text
1. Limpiar los discos en un PC.
2. Meter solo 1 HDD limpio en la bahia 1.
3. Preparar un PC Linux/Ubuntu como maquina de rescate.
4. Poner ese PC en la red 192.168.1.0/24.
5. Instalar CLUNC y TFTP.
6. Entrar al cargador Marvell/U-Boot de la LaCie.
7. Arrancar rescue RAM por TFTP.
8. Ejecutar el recovery seguro de 1 disco.
9. Reiniciar y abrir Dashboard por HTTP.
10. Anadir los otros discos desde Dashboard.
```

## Para quien es este repo

Para quien tenga una LaCie 5big Network 2 en uno de estos estados:

```text
LaCie Network Assistant no detecta la NAS.
LaCie Network Assistant la detecta mal pero no consigue recuperar.
La IP no responde a ping.
El navegador no abre el Dashboard.
La NAS no obtiene IP util por DHCP.
El recovery oficial no termina.
Solo se puede interactuar con el equipo usando CLUNC y el prompt Marvell>>.
```

## Que contiene

```text
Firmware oficial LaCie 5big Network 2 2.2.12.3.
Ficheros preparados para servidor TFTP.
Kernel rescue RAM para arrancar la NAS sin usar el sistema instalado.
Scripts para preparar el PC Linux de rescate.
Scripts para reparar el arranque instalado en el disco.
Documentacion paso a paso.
```

## Aviso importante

Este procedimiento borra discos. Usalo solo con discos sin datos importantes.

No empieces con los cinco discos metidos. El flujo probado usa **solo un disco limpio en la bahia 1**. Cuando el Dashboard funciona, los demas discos se agregan desde la interfaz web.

## Material necesario

```text
LaCie 5big Network 2.
Un disco duro limpio para la bahia 1.
Un PC con Ubuntu o Linux para hacer de maquina de rescate.
Cable Ethernet.
Router o switch con red 192.168.1.0/24.
CLUNC instalado en el PC Linux.
Servidor TFTP en el PC Linux.
Netcat, arp-scan, smbclient y herramientas basicas de red.
Un navegador para abrir el Dashboard.
```

Ejemplo probado:

```text
PC Linux de rescate: workstation-backup
Interfaz Ethernet del PC Linux: enp1s0
IP del PC Linux en la red de la LaCie: 192.168.1.200/24
IP temporal del rescue RAM de la LaCie: 192.168.1.250
IP normal de la LaCie tras arrancar: 192.168.1.40
MAC LaCie usada por CLUNC: 00:D0:4B:8E:54:7F
```

La red recomendada para este procedimiento es:

```text
192.168.1.0/24
```

La razon es que muchos equipos LaCie de esta familia trabajan de fabrica en esa red durante procesos de rescue/recovery. Puedes adaptar el procedimiento, pero si no sabes que cambiar, usa la red 192.168.1.0/24.

## Paso 0. Limpiar el disco antes de meterlo en la LaCie

Antes de empezar, limpia el disco que ira en la bahia 1. Esto elimina particiones anteriores, RAID viejo y firmas que pueden confundir al recovery.

En Windows, abre `cmd` o PowerShell como administrador y usa `diskpart` con mucho cuidado:

```text
diskpart
list disk
select disk X
clean
exit
```

Cambia `X` por el numero correcto del disco. Si eliges mal el disco, borraras otro disco del PC.

Para los otros discos que vayas a usar despues, haz tambien `clean`, pero no los metas todavia en la LaCie.

## Paso 1. Preparar fisicamente la LaCie

```text
1. Apaga la LaCie.
2. Desconecta el cable de corriente.
3. Saca todos los discos.
4. Mete solo 1 HDD limpio en la bahia 1.
5. Deja las bahias 2, 3, 4 y 5 vacias.
6. Conecta la LaCie por Ethernet a la misma red que el PC Linux.
7. Conecta corriente, pero no enciendas aun.
```

## Paso 2. Descargar y verificar el repositorio

En el Mac o PC donde descargues el repo:

```bash
git clone https://github.com/ih4x4y0u/lacie-5big-network2-frankenstein-rescue.git
cd lacie-5big-network2-frankenstein-rescue
shasum -a 256 -c MANIFEST.sha256
```

Debe terminar con todos los ficheros en `OK`.

## Paso 3. Copiar el pack al PC Linux de rescate

Ejemplo hacia un Ubuntu llamado `workstation-backup`:

```bash
scp -r ~/Downloads/lacie-5big-network2-frankenstein-rescue barsan@192.168.2.60:~/
```

Cambia usuario e IP por los de tu PC Linux.

En el PC Linux:

```bash
cd ~/lacie-5big-network2-frankenstein-rescue
shasum -a 256 -c MANIFEST.sha256
```

## Paso 4. Preparar Ubuntu como maquina de rescate

En el PC Linux:

```bash
cd ~/lacie-5big-network2-frankenstein-rescue
sudo bash scripts/workstation/prepare-workstation.sh
sudo bash scripts/workstation/install-tftp-files.sh
```

Esto instala o prepara herramientas como:

```text
tftpd-hpa
tftp-hpa
netcat-openbsd
smbclient
python3
arp-scan
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

## Paso 5. Configurar red del PC Linux

El PC Linux debe tener una interfaz Ethernet en la red de la LaCie.

Ejemplo probado:

```text
Interfaz: enp1s0
IP: 192.168.1.200/24
```

Comprueba:

```bash
ip -br a
```

Si tu interfaz no tiene IP en `192.168.1.0/24`, asignala desde NetworkManager, Netplan o la herramienta de red de tu Ubuntu.

## Paso 6. Instalar o tener CLUNC

CLUNC es la herramienta que permite hablar con el cargador de arranque de la LaCie antes de que Linux arranque.

El comando probado fue:

```bash
cd ~/clunc
sudo env PATH="$HOME/clunc/build:$PATH" ./clunc -v -m 00:D0:4B:8E:54:7F -i 192.168.1.250
```

Si tu LaCie usa otra MAC, cambiala. En este caso la MAC usada fue:

```text
00:D0:4B:8E:54:7F
```

Deja CLUNC esperando y enciende la LaCie.

Debe salir:

```text
Marvell>>
```

Si no sale tras unos segundos, pulsa Enter una vez.

## Paso 7. Arrancar rescue RAM por TFTP

En `Marvell>>` pega:

```text
setenv bootargs 'console=ttyS0,115200 static_addr=192.168.1.250 tftp_server=192.168.1.200 mode=telnet'
tftp 0x800000 uImage-lacie-rescue
bootm 0x800000
```

Esto no arranca desde el disco. Carga un Linux temporal en RAM desde el servidor TFTP del PC Linux.

## Paso 8. Entrar al rescue RAM

En otra terminal del PC Linux:

```bash
nc 192.168.1.250 23
```

Si ves caracteres raros, pulsa Enter una vez.

Debes llegar a:

```text
#
```

## Paso 9. Confirmar que solo hay un HDD

Dentro del rescue:

```sh
cat /proc/partitions
```

Debe salir un solo disco, normalmente:

```text
sda
```

No deben salir `sdb`, `sdc`, `sdd` ni `sde` en esta fase.

Si salen mas discos, apaga, deja solo el disco de bahia 1 y repite.

## Paso 10. Lanzar el recovery seguro de 1 HDD

Dentro del rescue:

```sh
cd /tmp
tftp -g -r lacie-one-disk-safe-recovery.sh 192.168.1.200
sh lacie-one-disk-safe-recovery.sh
```

El script hace esto:

```text
Ejecuta /nas-rescue/main.sh.
Detecta el fallo tipico de refresco tardio de /dev/sda8.
Relanza una segunda pasada si las particiones ya existen.
Monta /dev/sda9.
Escribe passwd, group, shadow, gshadow y fstab.
Verifica esos cinco ficheros.
Hace sync.
```

Durante el proceso se pueden ver muchas lineas como estas:

```text
connect_to_notifier: connect failed: Connection refused
ERROR: send_event_notification failed
Error when sending notification. Continue...
```

Esos avisos son normales dentro del rescue RAM.

Si el script termina bien, debe mostrar:

```text
LACIE_ONE_DISK_SAFE_RECOVERY_OK
```

## Paso 11. Reiniciar

Dentro del rescue:

```sh
sync
reboot -f
```

Espera 4 o 5 minutos.

## Paso 12. Comprobar red y Dashboard

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

## Paso 13. Primer arranque en Dashboard

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

## Paso 14. Agregar los otros discos

Solo despues de confirmar Dashboard y sistema base:

```text
1. Apaga desde Dashboard si es posible.
2. Inserta los otros HDD limpios.
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
