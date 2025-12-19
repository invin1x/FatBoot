#!/bin/bash

# Recreate build directory
rm -rf ../bin
mkdir ../bin

# Assembly test program
nasm -f bin -o ../bin/test.bin test.asm

# Create, format and mount raw disk image
dd if=/dev/zero of=../bin/image.bin bs=1M count=100     # 100 MiB disk
mkfs.fat -F 16 ../bin/image.bin
sudo mount ../bin/image.bin ../bin/mnt --mkdir

# Copy test program
sudo cp ../bin/test.bin ../bin/mnt/TEST.BIN

# Unmount the image
sudo umount ../bin/mnt

# Apply ZBS
../apply-zbs.sh ../bin/image.bin FAT16 0 TEST.BIN 0x1234:0x5678 0x1234:0x5678

# Test it in QEMU
qemu-system-i386 -m 1M -hda ../bin/image.bin -monitor stdio
