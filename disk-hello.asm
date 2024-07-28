; write hello world to the screen using screen memory

; how to build: assemble separately, then concat with dd (maybe there's a binary cat?)
; ./build.sh ./bootloader.asm
; ./build.sh ./disk-hello.asm
; cat bootloader.bin disk-hello.bin > fusion.bin
; ./qemu.sh fusion.bin

entry:
    org 0x0600 ; should match bootloader code

    mov ax,0x0002 ; set video mode to color text
    int 0x10 ; call interrupt to set video mode

    mov ax,0xb800 ; update segment to point to screen memory
    mov ds,ax
    mov es,ax

    cld ; clear direction flag - makes sure di increments instead of decrements on stosw

    xor di,di ; set destination index to 0

    mov ax,0x1a48 ; bg=blue, fg=light green, 'H'
    stosw ; store ax in screen memory and increment di by 2

    mov ax,0x1b45 ; blue/aqua 'E'
    stosw

    mov ax,0x1c4c ; blue/light red 'L'
    stosw

    mov ax,0x1d4c ; blue/light purple 'L'
    stosw

    mov ax,0x1e4f ; blue/light yellow 'O'
    stosw

    ; end of program
    jmp $
