#!/bin/bash

# Comprobar si se ha pasado un archivo como argumento
if [ ]; then
    echo "Uso: $0 archivo.asm"
    exit 1
fi

ARCHIVO_ASM=$1
NOMBRE_BASE=$(basename "$ARCHIVO_ASM" .asm)
IMAGEN_OUT="${NOMBRE_BASE}.img"

echo "--- Iniciando proceso para $ARCHIVO_ASM ---"

# 1. Ensamblado con NASM (como indica la página 17 del PDF)
echo "[1/3] Ensamblando con NASM..."
nasm -f bin "$ARCHIVO_ASM" -o "$IMAGEN_OUT"

if [ ]; then
    echo "OK: Archivo binario generado: $IMAGEN_OUT"
else
    echo "ERROR: Fallo en el ensamblado."
    exit 1
fi

# 2. Verificación de tamaño (Requerimiento de Bootloader: 512 bytes)
TAMANO=$(stat -c%s "$IMAGEN_OUT")
echo "[2/3] Verificando tamaño del sector: $TAMANO bytes"

if [ ]; then
    echo "ADVERTENCIA: El archivo no mide 512 bytes. Puede que no arranque correctamente."
fi

# 3. Ejecución en QEMU (Comando según página 17 del PDF)
echo "[3/3] Lanzando QEMU..."
qemu-system-i386 -drive file="$IMAGEN_OUT",format=raw,index=0,if=floppy

echo "--- Proceso finalizado ---"