#!/bin/bash

set +x  # Disable commands echo
set -e  # Exit on error

# Show help message if argument count is wrong
if [ $# -ne 6 ]; then
    echo 'Use: apply.sh'
    echo '  <target>           Target block device or file.'
    echo '  <filesystem>       Filesystem type.'
    echo '  <offset>           Filesystem offset in sectors.'
    echo '  <load_filename>    File to load.'
    echo '  <load_to_seg:off>  segment:offset to load file to.'
    echo '  <jump_to_seg:off>  segment:offset to jump to after loading.'
    echo
    echo 'Examples:'
    echo '  # The FAT12 boot sector code that loads KERNEL.BIN to 0x100:0 and'
    echo '  # jumps to 0x110:0 will be written in the 64th sector of /dev/fda,'
    echo '  # assuming it is the start of a FAT12 filesystem.'
    echo '  apply.sh /dev/fda FAT12 63 KERNEL.BIN 0x100:0 0x110:0'
    echo
    echo '  # The FAT16 boot sector code that loads PROG.BIN to 0x1234:0x5678'
    echo '  # and jumps to 0x4321:0xABCD will be written in the 1st sector of'
    echo '  # disk.raw, assuming it is the start of a FAT16 filesystem.'
    echo '  apply.sh disk.raw FAT16 0 PROG.BIN 0x1234:0x5678 0x4321:0xABCD'
    echo
    exit 1
fi

target=$1
filesystem=$2
offset=$3
filename=$4
IFS=":" read -r load_segment load_offset <<< "$5"
IFS=":" read -r jump_segment jump_offset <<< "$6"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/fat-boot"

rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Converts filename to 8.3 format
filename_to_8_3() {
    # Check if filename is empty
    [[ -z "$filename" ]] && {
        echo Error! Empty filename.
        return 1
    }

    # Separate name and extention
    local name="${filename%.*}"
    local ext=""
    [[ "$filename" == *.* ]] && ext="${filename##*.}"

    # Upper register
    name="${name^^}"
    ext="${ext^^}"

    # Check name and extension length
    if (( ${#name} == 0 || ${#name} > 8 )); then
        echo Error! A file name must be 1-8 characters long.
        return 1
    elif (( ${#ext} > 3 )); then
        echo Error! A file extension must not exceed 3 characters.
        return 1
    fi

    if [[ -n "$ext" ]]; then
        filename=$(printf "%-8s%-3s" "$name" "$ext")
    else
        filename=$(printf "%-8s   " "$name")
    fi
}

# FAT16
if [[ "$filesystem" == "FAT16" ]]; then
    filename_to_8_3
    nasm -f bin -o "$TEMP_DIR/fat16.bin" "$SCRIPT_DIR/src/fat16.asm" \
        -DFILENAME="\"$filename\"" \
        -DLOAD_SEGMENT="$load_segment" \
        -DLOAD_OFFSET="$load_offset" \
        -DJMP_SEGMENT="$jump_segment" \
        -DJMP_OFFSET="$jump_offset"
    dd if="$TEMP_DIR/fat16.bin" of="$target" bs=1 seek=$((offset*512+62)) conv=notrunc
    echo Successful!
    exit 0

# FAT12
elif [[ "$filesystem" == "FAT12" ]]; then
    filename_to_8_3
    nasm -f bin -o "$TEMP_DIR/fat12.bin" "$SCRIPT_DIR/src/fat12.asm" \
        -DFILENAME="\"$filename\"" \
        -DLOAD_SEGMENT="$load_segment" \
        -DLOAD_OFFSET="$load_offset" \
        -DJMP_SEGMENT="$jump_segment" \
        -DJMP_OFFSET="$jump_offset"
    dd if="$TEMP_DIR/fat12.bin" of="$target" bs=1 seek=$((offset*512+62)) conv=notrunc
    echo Successful!
    exit 0

# Unsupported FS
else
    echo The filesystem specified is not supported.
    exit 1
fi
