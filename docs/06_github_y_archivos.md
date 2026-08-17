# GitHub y archivos grandes

El fichero GPL original supera 100 MB, por eso se divide en partes dentro de:

```text
firmware/gpl_code/
```

Reconstruccion:

```bash
cd firmware/gpl_code
./reassemble-gpl.sh
```

Comprueba hashes:

```bash
sha256sum -c MANIFEST.sha256
```

