org 0x0100

; TODO: should I just use 2 bytes for both of x and y? easy to get confused with single bytes
player_x: equ 0x0200      ; 2 bytes for player position
player_y: equ 0x0201

level_dim: equ 25
level_size: equ 400         ; level_dim^2

video_segment: equ 0xB800   ; Segment address for video memory
row_width: equ 80           ; Width of the screen in characters

; https://www.lookuptables.com/text/extended-ascii-table
; https://www.rapidtables.com/convert/number/decimal-to-hex.html?x=247
wall_char: equ 0x04b2 ; black bg, red fg, heavy texture ▓
empty_char: equ 0x07b0 ; black bg, grey fg, light texture ░
fog_char: equ 0x07f7 ; black bg, grey fg, almost equal ≈
player_char: equ 0x0f40 ; black bg, white fg, @

start:
    mov ax,0x0002 ; set video mode to color text
    int 0x10 ; call interrupt to set video mode

    ; Set up segments
    mov ax,cs
    mov ds,ax
    mov ax, video_segment
    mov es,ax

    ; Set player coordinate
    mov byte [player_x],5
    mov byte [player_y],7

init_board:
    cld ; clear direction flag - di will increment
    xor di,di ; set di to 0

    mov cx,level_size
    xor dx,dx
init_board_loop:
    ; store everywhere on screen
    mov ax, fog_char
    stosw

    ; newline logic
    inc dx
    cmp dx, level_dim
    jl continue_board_loop ; jump if we are not yet at newline
    add di, (row_width - level_dim) * 2
    xor dx, dx

continue_board_loop:
    loop init_board_loop          ; Decrement CX, if CX != 0, loop back

draw_player:
    movzx ax, byte [player_y] ; Zero-extend player_y to ax
    mov dl,row_width*2
    mul dl
    movzx dx, byte [player_x] ; Zero-extend player_x to dx
    add ax, dx
    add ax, dx
    mov di,ax
    ; mov di,[player_pos]
    mov ax, player_char
    stosw

get_input:
    ; press any key to exit
    call read_keyboard

    cmp al,0x1b ; check for escape key pressed
    je do_exit

    cmp al,'w'
    je go_up

    cmp al,'a'
    je go_left

    cmp al,'d'
    je go_right

    cmp al,'s'
    je go_down

    jmp get_input

go_up:
    dec byte [player_y]
    jmp init_board

go_left:
    dec byte [player_x]
    jmp init_board

go_down:
    inc byte [player_y]
    jmp init_board

go_right:
    inc byte [player_x]
    jmp init_board



do_exit:
    int 0x20                ; Terminate the program

; times 510-($-$$) db 0       ; Fill the rest of the boot sector with zeroes
; dw 0xAA55                   ; Boot sector signature

; read keyboard input into AL
read_keyboard:
    ; save other registers
    push bx
    push cx
    push dx
    push si
    push di

    mov ah,0x00 ; set AH for keyboard read
    int 0x16 ; call interrupt to read keyboard

    ; restore other registers
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret ; returns to caller
