# LaCie 5big Network 2 Recovery Toolkit

Este repositorio documenta un procedimiento de recuperación para una **LaCie 5big Network 2** que no puede recuperarse mediante las herramientas habituales de LaCie.

El caso cubierto es el siguiente:

```text
La NAS enciende, pero no responde en la red.
LaCie Network Assistant no detecta el equipo.
LaCie Network Assistant no consigue iniciar ni completar el proceso de recuperación.
La dirección IP conocida no responde a ping.
El Dashboard web no carga.
No hay acceso SMB a los recursos compartidos.
No es posible completar la configuración desde la herramienta oficial.
```

En esta situación, el sistema interno instalado en los discos puede estar incompleto, dañado o en un estado que impide el arranque normal. La recuperación se realiza arrancando un sistema temporal en RAM desde red, instalando de nuevo el sistema oficial en un disco sin particiones ni metadatos previos y aplicando una reparación mínima antes del primer arranque normal.

El procedimiento validado utiliza este orden:

```text
1. Inicializar la tabla de particiones de los discos en un PC.
2. Instalar solo un HDD inicializado en la bahía 1.
3. Preparar un PC con Ubuntu/Linux como estación de rescate.
4. Conectar la estación de rescate y la LaCie a una red 192.168.1.0/24.
5. Preparar CLUNC, TFTP y herramientas de diagnóstico.
6. Acceder al cargador Marvell/U-Boot de la LaCie.
7. Arrancar el entorno rescue RAM por TFTP.
8. Ejecutar el recovery seguro de un disco.
9. Reiniciar y acceder al Dashboard por HTTP.
10. Añadir los discos restantes desde el Dashboard.
```

## Alcance

Este repositorio está pensado para escenarios en los que la recuperación normal no es suficiente:

```text
LaCie Network Assistant no detecta la NAS.
LaCie Network Assistant detecta el equipo pero no consigue recuperarlo.
La IP conocida no responde a ping.
El Dashboard no abre desde el navegador.
La NAS no obtiene una IP útil por DHCP.
El recovery oficial se interrumpe o queda incompleto.
Solo se puede interactuar con el equipo mediante CLUNC y el prompt Marvell>>.
```

## Contenido del repositorio

```text
Firmware oficial LaCie 5big Network 2 2.2.12.3.
Ficheros preparados para servidor TFTP.
Kernel rescue RAM para iniciar la NAS sin depender del sistema instalado en disco.
Scripts para preparar la estación Linux de rescate.
Scripts para reparar el arranque instalado en el disco.
Documentación paso a paso.
```

## Advertencia sobre datos

Este procedimiento elimina las tablas de particiones y los metadatos existentes de los discos utilizados. Debe ejecutarse únicamente con discos sin datos importantes o con datos previamente respaldados.

No inicies el proceso con los cinco discos instalados. El flujo validado utiliza **un solo disco inicializado en la bahía 1**. Una vez que el Dashboard funciona, los discos restantes se añaden desde la interfaz web.

## Material necesario

```text
LaCie 5big Network 2.
Un disco duro sin particiones previas para la bahía 1.
Un PC con Ubuntu o Linux para actuar como estación de rescate.
Cable Ethernet.
Router o switch con red 192.168.1.0/24.
CLUNC instalado en el PC Linux.
Servidor TFTP en el PC Linux.
Netcat, arp-scan, smbclient y herramientas básicas de red.
Un navegador para acceder al Dashboard.
```

Ejemplo validado:

```text
Estación Linux de rescate: workstation-backup
Interfaz Ethernet de rescate: enp1s0
IP de la estación de rescate: 192.168.1.200/24
IP temporal del rescue RAM de la LaCie: 192.168.1.250
IP normal de la LaCie tras el arranque: 192.168.1.40
MAC LaCie usada por CLUNC: 00:D0:4B:8E:54:7F
```

La red recomendada para este procedimiento es:

```text
192.168.1.0/24
```

Esta red se utiliza porque el entorno de recuperación de estos equipos LaCie trabaja habitualmente con direcciones de ese rango. El procedimiento puede adaptarse, pero si no se conocen los cambios necesarios, usa la red 192.168.1.0/24.

## Paso 0. Inicializar los discos antes de instalarlos en la LaCie

Antes de comenzar, elimina la tabla de particiones, las firmas de sistemas de ficheros y los metadatos RAID del disco que se instalará en la bahía 1. Esto evita que el recovery interprete estructuras antiguas como válidas.

En Windows, abre `cmd` o PowerShell como administrador y usa `diskpart` con cuidado:

```text
diskpart
list disk
select disk X
clean
exit
```

Cambia `X` por el número correcto del disco. Seleccionar el disco equivocado borrará otro dispositivo del PC.

Ejecuta el mismo proceso sobre los discos restantes que vayas a añadir más adelante, pero no los instales todavía en la LaCie.

## Paso 1. Preparar físicamente la LaCie

```text
1. Apaga la LaCie.
2. Desconecta el cable de corriente.
3. Retira todos los discos.
4. Instala solo un HDD inicializado en la bahía 1.
5. Deja vacías las bahías 2, 3, 4 y 5.
6. Conecta la LaCie por Ethernet a la misma red que el PC Linux.
7. Conecta la corriente, pero no enciendas todavía el equipo.
```

## Paso 2. Descargar y verificar el repositorio

En el Mac o PC desde el que descargues el repo:

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

## Paso 4. Preparar Ubuntu como estación de rescate

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

Verifica que TFTP tiene los ficheros necesarios:

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

## Paso 5. Configurar la red del PC Linux

El PC Linux debe tener una interfaz Ethernet en la red de la LaCie.

Ejemplo validado:

```text
Interfaz: enp1s0
IP: 192.168.1.200/24
```

Comprueba:

```bash
ip -br a
```

Si tu interfaz no tiene IP en `192.168.1.0/24`, asígnala desde NetworkManager, Netplan o la herramienta de red de tu distribución.

## Paso 6. Instalar o preparar CLUNC

CLUNC permite comunicarse con el cargador de arranque de la LaCie antes de que arranque Linux.

El comando validado fue:

```bash
cd ~/clunc
sudo env PATH="$HOME/clunc/build:$PATH" ./clunc -v -m 00:D0:4B:8E:54:7F -i 192.168.1.250
```

Si tu LaCie usa otra MAC, cámbiala. En este caso la MAC utilizada fue:

```text
00:D0:4B:8E:54:7F
```

Deja CLUNC esperando y enciende la LaCie.

Debe mostrarse:

```text
Marvell>>
```

Si no se muestra tras unos segundos, pulsa Enter una vez.

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

Si se muestran caracteres extraños, pulsa Enter una vez.

Debes llegar a:

```text
#
```

## Paso 9. Confirmar que solo hay un HDD

Dentro del rescue:

```sh
cat /proc/partitions
```

Debe mostrarse un solo disco, normalmente:

```text
sda
```

No deben mostrarse `sdb`, `sdc`, `sdd` ni `sde` en esta fase.

Si se muestran más discos, apaga el equipo, deja solo el disco de bahía 1 y repite.

## Paso 10. Lanzar el recovery seguro de un HDD

Dentro del rescue:

```sh
cd /tmp
tftp -g -r lacie-one-disk-safe-recovery.sh 192.168.1.200
sh lacie-one-disk-safe-recovery.sh
```

El script realiza estas acciones:

```text
Ejecuta /nas-rescue/main.sh.
Detecta el fallo típico de refresco tardío de /dev/sda8.
Relanza una segunda pasada si las particiones ya existen.
Monta /dev/sda9.
Escribe passwd, group, shadow, gshadow y fstab.
Verifica esos cinco ficheros.
Ejecuta sync.
```

Durante el proceso pueden mostrarse muchas líneas como estas:

```text
connect_to_notifier: connect failed: Connection refused
ERROR: send_event_notification failed
Error when sending notification. Continue...
```

Estos avisos son normales dentro del rescue RAM.

Si el script termina correctamente, debe mostrar:

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
1. Completa el asistente inicial.
2. Configura el usuario administrador.
3. Revisa la información de unidad.
4. Crea un recurso compartido simple, por ejemplo Public.
5. Comprueba acceso SMB si lo necesitas.
```

Prueba SMB desde Linux:

```bash
smbclient -L //192.168.1.40 -U admin -m NT1 --option='client min protocol=NT1'
```

## Paso 14. Agregar los otros discos

Solo después de confirmar Dashboard y sistema base:

```text
1. Apaga desde Dashboard si es posible.
2. Inserta los otros HDD inicializados.
3. Enciende.
4. Entra al Dashboard.
5. Crea o reconstruye RAID desde la interfaz.
6. Espera a que termine la sincronización.
```

No cortes corriente durante la sincronización RAID.

## Errores conocidos

### `mdadm: Cannot open /dev/sda8`

Puede ocurrir en la primera pasada porque el kernel antiguo no refresca la tabla de particiones a tiempo.

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

## Estado validado

Este flujo fue validado con:

```text
LaCie 5big Network 2
Firmware capsule 2.2.12.3
Recovery RAM por CLUNC
1 HDD HGST 4 TB en bahía 1
IP rescue 192.168.1.250
IP normal 192.168.1.40
Dashboard por HTTP funcionando
```

## Licencia

Scripts y documentación propia bajo MIT.

Firmware, capsule, GPL y componentes LaCie Seagate mantienen su origen y sus licencias correspondientes.
