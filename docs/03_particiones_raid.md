# Particiones y RAID

Tras recovery oficial en un disco se esperan particiones GPT del sistema LaCie.

Puntos utiles:

```text
sda6 kernel
sda7 bootfs
sda8 rootfs
sda9 overlay persistente
sda2 datos grandes
```

El firmware suele levantar arrays `md` incluso con un solo disco:

```text
md0 sistema
md1 rootfs
md2 overlay
md4 datos
```

El volumen de datos se monta como XFS. Si `fstab` falta, el Dashboard puede mostrar la unidad a `0 B` aunque el RAID exista.
