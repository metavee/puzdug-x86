org 0x0100; for dosbox
; org 0x7c00 ; for boot

section .bss

level_width: equ 27
level_height: equ 18
level_size: equ level_width*level_height         ; level_width * level_height

player_pos: resb 2
level_addr: resb level_size*2
fog_addr: resb level_size
player_health: equ (string + 15)

video_segment: equ 0xB800   ; Segment address for video memory
row_width: equ 80           ; Width of the screen in characters

; https://www.lookuptables.com/text/extended-ascii-table
; https://www.rapidtables.com/convert/number/decimal-to-hex.html?x=247
wall_char: equ 0x04b2 ; black bg, red fg, heavy texture ▓
empty_char: equ 0x072e ; black bg, grey fg, .
fog_char: equ 0x07f7 ; black bg, grey fg, almost equal ≈
player_char: equ 0x0f40 ; black bg, white fg, @
basic_enemy_char: equ 0x03EA ; black bg, aqua fg, omega

; hardcoded single wall in array index
wall1_start_index: equ 2 * (3*level_width + 13)
wall1_length: equ 12
vertical_step: equ 2*level_width
horizontal_step: equ 2

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
    mov byte [player_health],15

init_level:
    ; Set up level array
    mov bx, level_addr
    mov di, fog_addr
    mov cx,level_size
init_level_loop:
    ; empty char by default
    mov word [bx], empty_char
    mov byte [di], 1

    add bx, 2
    add di, 1
    loop init_level_loop

init_boundary_walls:
    mov ax, horizontal_step
    mov bx, level_addr
    mov cx, level_width
    call fill_wall

    mov bx, (level_addr + 2  * (level_height - 1) * level_width)
    mov cx, level_width
    call fill_wall

    mov ax, vertical_step
    mov bx, level_addr
    mov cx, level_height
    call fill_wall

    mov bx, (level_addr + 2 * (level_width - 1))
    mov cx, level_height
    call fill_wall

init_wall1:
    mov bx, (level_addr + wall1_start_index)
    mov cx, wall1_length
    call fill_wall

spawn_enemy:
    mov bx, (level_addr + 2 * (3 * level_width + 3))
    mov word [bx], basic_enemy_char

    ; initial fog clear
    mov dx, [player_pos]
    call reveal_fog

render_level:
    cmp byte [player_health], 0
    je do_exit

    cld ; clear direction flag - di will increment
    xor di,di ; set di to 0

    mov cx,level_size
    xor dx,dx

    mov bx,level_addr
    mov si,fog_addr
render_level_loop:
    ; store everywhere on screen
    mov al, [si]
    cmp al, 1
    jne render_no_fog
    mov ax, fog_char
    jmp render_char
render_no_fog:
    mov ax, [bx]
render_char:
    stosw
    add bx,2
    add si,1

    ; newline logic
    inc dx
    cmp dx, level_width
    jl continue_level_loop ; jump if we are not yet at newline
    add di, (row_width - level_width) * 2
    xor dx, dx

continue_level_loop:
    loop render_level_loop          ; Decrement CX, if CX != 0, loop back

draw_player:
    mov dx, [player_pos]
    mov cx, row_width
    call xy2offset
    shl dx,1
    mov di,dx

    mov ax, player_char
    stosw

draw_health:
    mov bx,string
    mov dl,level_width+5
    mov dh,0x05
    call draw_text
    mov di, (row_width * 5 + level_width + 3) * 2
    mov ax, basic_enemy_char
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
    jmp can_move
go_down:
    inc dh
    jmp can_move
go_left:
    dec dl
    jmp can_move
go_right:
    inc dl
can_move:
    ; check for wall - coordinate conversion
    push dx
    mov cx, level_width
    call xy2offset
    shl dx,1
    mov bx,dx
    add bx,level_addr
    pop dx

    cmp word [bx],wall_char
    je hit_wall

    cmp word [bx],basic_enemy_char
    je hit_basic_enemy

    ; passed checks - update position
    mov [player_pos],dx
    call reveal_fog
    jmp render_level

hit_wall:
    ; TODO: set status flag
    jmp render_level

hit_basic_enemy:
    dec byte [player_health]
    ; TODO: run one exchange of combat
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

xy2offset:
    ; take xy value (dh=y, dl=x) and turn into a 1d offset (replace dx)
    ; cx should contain the effective row width
    push ax
    push dx ; save value since multiplication overwrites

    ; Calculate the row offset
    movzx ax, dh        ; Move y-coordinate to ax (without sign extension)
    mul cx              ; ax *= row_width

    ; Calculate total offset with x-coordinate
    pop dx
    and dx, 0x00FF  ; Mask with 0x00FF to zero out DH

    add ax, dx          ; Combine the x-offset with the row offset
    mov dx, ax          ; Resulting offset in dx

    pop ax ; Restore preserved registers             
    ret

reveal_fog:
    ; take xy value (dh=y, dl=x) and unset fog array 2 squares around it
    ; sets cx


    ; reveal line with start=dx, xy offset=ax, length=cx
    ; right
    mov ax,0x0001
    mov cx,2
    call reveal_fog_line

    ; down
    mov ax,0x0100
    mov cx,2
    call reveal_fog_line

    ; left
    mov ax,0x00ff
    mov cx,2
    call reveal_fog_line

    ; up
    mov ax,0xff00
    mov cx,2
    call reveal_fog_line

    ; lower-right
    mov ax,0x0101
    mov cx,1
    call reveal_fog_line

    ; lower-left
    mov ax,0x01ff
    mov cx,1
    call reveal_fog_line

    ; upper-left
    mov ax,0xffff
    mov cx,1
    call reveal_fog_line

    ; upper-right
    mov ax,0xff01
    mov cx,1
    call reveal_fog_line

    ret
reveal_fog_line:
    push dx
reveal_fog_line_loop:
    push dx
    ; add offset. do 8-bit adds so that we can add negative numbers
    add dh,ah
    add dl,al
    push cx
    mov cx,level_width
    call xy2offset ; convert xy coord to 1d offset
    ; clear fog at location
    mov di,dx
    add di,fog_addr
    mov byte [di], 0

    ; check contents of level at location
    shl dx,1 ; level array has 2 byte offsets
    mov bx,dx
    add bx,level_addr

    pop cx
    pop dx
    ; re-add offset so we have it for the next loop
    add dh,ah
    add dl,al
    
    cmp word [bx],wall_char
    je end_reveal_fog_line
    loop reveal_fog_line_loop

end_reveal_fog_line:
    pop dx
    ret

fill_wall:
    ; ax has stride
    ; bx has wall start index
    ; cx has length
    mov word [bx], wall_char
    add bx, ax
    loop fill_wall
    ret

; ax is clobbered
; bx is start of null-terminated string (clobbered)
; dx is draw x/y (clobbered)
draw_text:
    mov cx, row_width
    call xy2offset
    shl dx,1
    mov di,dx
    mov ah, 0x0f ; white text black bg
draw_text_loop:
    mov al,[bx]
    test al,al
    je draw_text_end
    stosw
    inc bx
    jmp draw_text_loop
draw_text_end:
    ret

section .data
string:
    db "Player health:   ", 0
