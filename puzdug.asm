    org 0x0100

level: equ 0x0300
board_size: equ 3

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
show_loop:
    mov al,[bx]
    call display_letter

    ; ; move to new line if (bx+1) % 20 == 0
    ; push ax
    ; push cx
    ; push dx

    ; pop dx
    ; pop cx
    ; pop ax

    inc bx
    loop show_loop

do_exit:
    int 0x20
