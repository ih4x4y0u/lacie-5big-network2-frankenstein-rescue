# Errores y sintomas

## Solo entra en Marvell

Usa `pyclunc.py` y arranca rescue RAM por TFTP.

## Dashboard no abre

Revisa que el firmware haya arrancado y aplica `lacie-basefix-minimal.sh` desde rescue.

## Unidad de red a 0 B

Causa habitual en este caso:

```text
/etc/fstab ausente
```

Solucion:

```sh
sh lacie-basefix-minimal.sh
```

## SSH rechaza conexion

En firmware LaCie puede estar desactivado. El rescue RAM entra por telnet solo durante la sesion de rescate.

## HTTPS falla en navegador moderno

Usa HTTP para Dashboard:

```text
http://IP_DEL_NAS/?locale=es
```
