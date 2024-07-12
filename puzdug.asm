    org 0x0100

level: equ 0x0300
board_size: equ 400

wipe_level:
    mov bx,level
    mov cx,board_size
    mov al,'.'
wipe_loop:
    mov [bx],al ; store '.' in memory @ bx
    inc bx ; mov address up
    loop wipe_loop ; dec cx. jnz wipe_loop

show_board:
    mov bx,level
    mov cx,board_size
    mov dl,0
show_loop:
    mov al,[bx]
    call display_letter

    inc dl
    ; if dl >= 20 then reset to 0 and print newline
    cmp dl, 20
    jl continue_loop
    mov ah, 0x02  ; Function to move cursor to start (carriage return)
    mov dl, 0x0D  ; Carriage return character
    int 0x21      ; DOS interrupt to perform output
    mov ah, 0x02  ; Function to output
    mov dl, 0x0A  ; Line feed character
    int 0x21      ; DOS interrupt to perform output
    mov dl, 0

continue_loop:
    inc bx
    loop show_loop

do_exit:
    int 0x20
