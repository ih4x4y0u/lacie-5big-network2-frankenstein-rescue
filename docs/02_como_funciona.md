# Como funciona

## CLUNC y NetConsole

LaCie usa U-Boot Marvell con consola de red. CLUNC envia paquetes LUMP por UDP al arranque. U-Boot se detiene y abre una consola por UDP en el puerto 6666.

## Rescue RAM

El rescue RAM es un Linux temporal cargado por TFTP. Vive en memoria y permite reparar discos sin depender del firmware instalado.

Cadena completa:

```text
PC Linux
pyclunc.py
Marvell>>
TFTP uImage-lacie-rescue
Linux rescue en RAM
telnet 192.168.1.250
recovery o reparacion
firmware LaCie desde disco
Dashboard HTTP
SMB
```

## Basefix

El fallo observado en este modelo fue un overlay sin ficheros base en `/etc`. DBus, Samba, HAL y Dashboard dependen de esos ficheros.

`lacie-basefix-minimal.sh` repone lo minimo:

```text
passwd
group
shadow
gshadow
fstab
```

No crea datos de usuario del NAS ni contenido compartido.
