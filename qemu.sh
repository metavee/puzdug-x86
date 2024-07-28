#!/bin/bash

set -e

# boot from floppy
# qemu-system-x86_64 -fda $1

# or hard drive, it seems to make little difference except that QEMU will try hard drive before floppy normally
qemu-system-i386 -cpu base -m 1024k -drive file=$1,format=raw -serial stdio
