infile := "puzdug.asm"
infile_no_ext := shell("basename " + infile + " .asm")

dos_out := infile_no_ext + ".com"
stage2_out := infile_no_ext + ".bin"
listing_out := infile_no_ext + ".lst"

bootloader_in := "bootloader.asm"
bootloader_out := "bootloader.bin"

boot_out := infile_no_ext + "-boot.img"

# # Size of 360 KB floppy in bytes
TARGET_SIZE := "368640"

qemu: padded-bootable
    qemu-system-i386 -cpu base -m 1024k -drive if=floppy,file={{boot_out}},format=raw -serial stdio

blinken: unpadded-bootable
    blinkenlights -r {{boot_out}}

build: build-dos padded-bootable

unpadded-bootable: build-bootloader
    cat {{bootloader_out}} {{stage2_out}} > {{boot_out}}

build-dos:
    nasm -f bin -D DOS -o {{dos_out}} {{infile}} -l {{listing_out}}

build-bootloader: build-stage2
    #!/bin/bash
    SECTOR_SIZE=512
    file_size=$(wc -c < "{{stage2_out}}")
    num_sectors=$(( (file_size + SECTOR_SIZE - 1) / SECTOR_SIZE ))

    nasm -f bin -DNUM_SECTORS=$num_sectors -DNUM_SECTORS_STR="\"$num_sectors\"" -o {{bootloader_out}} {{bootloader_in}}

build-stage2:
    nasm -f bin -D BOOT -o {{stage2_out}} {{infile}} -l {{listing_out}}

padded-bootable: unpadded-bootable
    #!/bin/bash
    set -euo pipefail

    target_size={{ TARGET_SIZE }}
    # Get the current size of the image file
    current_size=$(wc -c < {{boot_out}})
    # Calculate the number of bytes to pad with zeros
    padding_size=$((target_size - current_size))

    # Ensure the padding size is not negative
    if [[ "$padding_size" -ge 0 ]]; then
    # Pad the image file with zero bytes
    head -c $padding_size < /dev/zero >> {{boot_out}}
    echo "{{boot_out}} has been zero-padded to $target_size bytes."
    else
    echo "Error: {{boot_out}} is already larger than $target_size bytes."
    exit 1
    fi
