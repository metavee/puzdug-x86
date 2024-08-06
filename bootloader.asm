cpu	8086

org 0x7C00  ; Origin point for the bootloader (BIOS loads it here)

start:
    ; Save the drive number used to boot
    mov [boot_drive], dl

    ; Display a message to indicate bootloader is running
    mov si, init_msg
    call println

    mov si, loading_msg
    call println

    ; Load the second sector from the disk
    ; Use the drive number in 'boot_drive'
    mov ah, 0x02        ; BIOS read sector function
    mov al, NUM_SECTORS ; Number of sectors to read (from preprocessor arg)
    mov ch, 0x00        ; Cylinder number (0)
    mov cl, 0x02        ; Sector number (1-based, so 2 means second sector)
    mov dh, 0x00        ; Head number (0)
    mov dl, [boot_drive]; Drive number (used to boot)
    mov bx, 0x0600      ; Segment address to load the sector (0x0000:0x0600)
    int 0x13            ; Interrupt call to BIOS

    ; Check for errors
    jc disk_error       ; If carry flag is set, there was an error

    mov si, ready_msg
    call println
    call read_keyboard

    ; Jump to loaded code
    jmp 0x0000:0x0600   ; Segment:Offset where the second sector is loaded

disk_error:
    ; Display error message and halt
    mov si, err_msg
    call println
    jmp $

println:
    push ax
    push si
    mov ah, 0x0E        ; BIOS teletype function
print_char:
    mov al, [si]
    cmp al, 0
    je print_done
    int 0x10            ; BIOS video interrupt
    inc si
    jmp print_char
print_done:
    ; 2 newlines
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10

    pop si
    pop ax
    ret

; read keylevel input into AL; trash AH
read_keyboard:
    mov ah,0x00 ; set AH for keylevel read
    int 0x16 ; call interrupt to read keylevel

    ret ; returns to caller

boot_drive db 0         ; Storage for boot drive number

init_msg db 'Bootloader running...', 0
ready_msg db 'Loaded program into memory. Press any key to boot.', 0
loading_msg db 'Loading ', NUM_SECTORS_STR, ' sectors from disk...', 0
err_msg db 'Disk load error', 0

times 510-($-$$) db 0   ; Fill the rest of the 512 bytes with zeros
dw 0xAA55               ; Boot signature
