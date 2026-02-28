#!/bin/bash

nasm -f bin stage1.asm -o stage1.bin
nasm -f bin stage2.asm -o stage2.bin

cat stage1.bin stage2.bin > bootloader.bin

qemu-system-i386 -fda bootloader.bin
