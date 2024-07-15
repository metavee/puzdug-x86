    org 0x0100

player_pos: equ 0x0200 ; 2 byte
level: equ 0x0300
board_size: equ 400

    mov word [player_pos], 0 ; starting position

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
    ; check if we are at player_pos and print
    push bx
    mov bx,400
    sub bx,[player_pos]
    cmp cx, bx
    pop bx
    jne board_letter
    mov al,'@'
    call display_letter
    jmp board_newline

board_letter:
    mov al,[bx]
    call display_letter

board_newline:
    inc dl
    ; if dl >= 20 then reset to 0 and print newline
    cmp dl, 20
    jl continue_loop
    mov al,0x0D
    call display_letter
    mov al,0x0A
    call display_letter

    mov dl, 0

continue_loop:
    inc bx
    loop show_loop

do_exit:
    int 0x20
