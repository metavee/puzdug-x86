org 0x7C00  ; Origin point for the bootloader (BIOS loads it here)

start:
    ; Save the drive number used to boot
    mov [boot_drive], dl

    ; Display a message to indicate bootloader is running
    mov si, msg
    call print_string


    ; Load the second sector from the disk
    ; Use the drive number in 'boot_drive'
    mov ah, 0x02        ; BIOS read sector function
    mov al, 0x01        ; Number of sectors to read
    mov ch, 0x00        ; Cylinder number (0)
    mov cl, 0x02        ; Sector number (1-based, so 2 means second sector)
    mov dh, 0x00        ; Head number (0)
    mov dl, [boot_drive]; Drive number (used to boot)
    mov bx, 0x0600      ; Segment address to load the sector (0x0000:0x0600)
    int 0x13            ; Interrupt call to BIOS

    ; Check for errors
    jc disk_error       ; If carry flag is set, there was an error

    ; Jump to loaded code
    jmp 0x0000:0x0600   ; Segment:Offset where the second sector is loaded

disk_error:
    ; Display error message and halt
    mov si, err_msg
    call print_string
    jmp $

print_string:
    pusha
    mov ah, 0x0E        ; BIOS teletype function
print_char:
    mov al, [si]
    cmp al, 0
    je print_done
    int 0x10            ; BIOS video interrupt
    inc si
    jmp print_char
print_done:
    popa
    ret

boot_drive db 0         ; Storage for boot drive number

msg db 'Bootloader running...', 0
err_msg db 'Disk load error', 0

times 510-($-$$) db 0   ; Fill the rest of the 512 bytes with zeros
dw 0xAA55               ; Boot signature
