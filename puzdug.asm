org 0x0100

section .bss

player_pos: resb 2
level_addr resb 800

level_width: equ 25
level_height: equ 16
level_size: equ 400         ; level_width * level_height

video_segment: equ 0xB800   ; Segment address for video memory
row_width: equ 80           ; Width of the screen in characters

; https://www.lookuptables.com/text/extended-ascii-table
; https://www.rapidtables.com/convert/number/decimal-to-hex.html?x=247
wall_char: equ 0x04b2 ; black bg, red fg, heavy texture ▓
empty_char: equ 0x072e ; black bg, grey fg, .
fog_char: equ 0x07f7 ; black bg, grey fg, almost equal ≈
player_char: equ 0x0f40 ; black bg, white fg, @

; hardcoded single wall in array index
wall1_start_index: equ 2 * (2*level_width + 12)
wall1_length: equ 12
wall1_step: equ 2*level_width

section .text

start:
    mov ax,0x0002 ; set video mode to color text
    int 0x10 ; call interrupt to set video mode

    ; Set up segments
    mov ax,cs
    mov ds,ax
    mov ax, video_segment
    mov es,ax

    ; Set player coordinate
    mov byte [player_pos],5
    mov byte [player_pos+1],7

init_level:
    ; Set up level array
    mov bx, level_addr
    mov cx,level_size
    xor dx,dx
init_level_loop:
    ; empty char by default
    mov word [bx], empty_char
    add bx,2
    loop init_level_loop
init_wall1:
    mov bx, (level_addr + wall1_start_index)
    mov cx, wall1_length
init_wall1_loop:
    mov word [bx], wall_char
    add bx, wall1_step
    loop init_wall1_loop

render_level:
    cld ; clear direction flag - di will increment
    xor di,di ; set di to 0

    mov cx,level_size
    xor dx,dx

    mov bx,level_addr
render_level_loop:
    ; store everywhere on screen
    mov ax, [bx]
    stosw
    add bx,2

    ; newline logic
    inc dx
    cmp dx, level_width
    jl continue_level_loop ; jump if we are not yet at newline
    add di, (row_width - level_width) * 2
    xor dx, dx

continue_level_loop:
    loop render_level_loop          ; Decrement CX, if CX != 0, loop back

draw_player:
    movzx ax, byte [player_pos+1] ; Zero-extend player_y to ax
    mov dl,row_width*2
    mul dl
    movzx dx, byte [player_pos] ; Zero-extend player_x to dx
    add ax, dx
    add ax, dx
    mov di,ax

    mov ax, player_char
    stosw

get_input:
    ; dh/dl start as current position
    mov dx,[player_pos]
    ; mov dh,[player_pos]
    ; mov dl,[player_pos+1]

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
    dec dh
    cmp dh, 0
    js hit_wall
    jmp can_move
go_down:
    inc dh
    cmp dh, level_height
    jae hit_wall
    jmp can_move
go_left:
    dec dl
    cmp dl, 0
    js hit_wall
    jmp can_move
go_right:
    inc dl
    cmp dl, level_width
    jae hit_wall
can_move:
    ; check for wall - coordinate conversion
    movzx ax, dh
    push dx
    mov dl, row_width*2
    mul dl
    pop dx

    mov bx,level_addr
    add bx,ax

    movzx ax, dl
    add bx,ax
    add bx,ax

    cmp word [bx],wall_char
    je hit_wall

    ; passed checks - update position
    mov [player_pos],dx
    jmp render_level

hit_wall:
    ; TODO: set status flag
    jmp render_level

do_exit:
    int 0x20                ; Terminate the program

; times 510-($-$$) db 0       ; Fill the rest of the boot sector with zeroes
; dw 0xAA55                   ; Boot sector signature

; read keylevel input into AL
read_keyboard:
    ; save other registers
    push bx
    push cx
    push dx
    push si
    push di

    mov ah,0x00 ; set AH for keylevel read
    int 0x16 ; call interrupt to read keylevel

    ; restore other registers
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret ; returns to caller
