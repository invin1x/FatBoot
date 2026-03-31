#!/bin/bash

# Recreate build directory
rm -rf ../bin
mkdir ../bin

# Assembly test program
nasm -f bin -o ../bin/test.bin test.asm

# Create, format and mount raw disk image
dd if=/dev/zero of=../bin/image.bin bs=512 count=5760   # 2.88 MiB floppy
mkfs.fat -F 16 -g 2/36 -s 1 ../bin/image.bin
sudo mount ../bin/image.bin ../bin/mnt --mkdir

# Copy test program
sudo cp ../bin/test.bin ../bin/mnt/TEST.BIN

# Unmount the image
sudo umount ../bin/mnt

# Apply FatBoot
../apply.sh ../bin/image.bin FAT16 0 TEST.BIN 0x1234:0x5678 0x1234:0x5678

# Test it in QEMU
qemu-system-i386 -m 1M -fda ../bin/image.bin -monitor stdio
