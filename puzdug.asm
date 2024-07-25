org 0x0100; for dosbox
; org 0x7c00 ; for boot

section .bss

level_width: equ 27
level_height: equ 18
level_size: equ level_width*level_height         ; level_width * level_height

player_pos: resb 2
level_addr: resb level_size*2
fog_addr: resb level_size
player_addr: equ entity_arr
player_health_str_addr: equ (string + 4)

num_start_enemies: equ 8

current_hp_offset: equ 0
max_hp_offset: equ (current_hp_offset+1)
type_offset: equ (max_hp_offset+1)
max_entity_offset: equ (type_offset+1)
entity_arr: resb (max_entity_offset * (num_start_enemies + 1))

enemy_sentinel: equ 0x03

video_segment: equ 0xB800   ; Segment address for video memory
row_width: equ 80           ; Width of the screen in characters

; https://www.lookuptables.com/text/extended-ascii-table
; https://www.rapidtables.com/convert/number/decimal-to-hex.html?x=247
wall_char: equ 0x04b2 ; black bg, red fg, heavy texture ▓
empty_char: equ 0x072e ; black bg, grey fg, .
fog_char: equ 0x07f7 ; black bg, grey fg, almost equal ≈
player_char: equ 0x0f40 ; black bg, white fg, @
house_char: equ 0x0d7f ; black bg, pink fg, house symbol
tree_char: equ 0x0206 ; black bg, green fg, spade symbol

; hardcoded single wall in array index
wall1_start_index: equ 2 * (3*level_width + 13)
wall1_length: equ 12
vertical_step: equ 2*level_width
horizontal_step: equ 2

; https://en.wikipedia.org/wiki/Linear_congruential_generator
rng_state: resb 2
rng_a: equ 4937; (some multiple of 4) + 1. large but smaller than m
rng_m: equ 8191 ; prime
rng_c: equ 31 ; small prime

section .text

start:
    mov ax,0x0002 ; set video mode to color text
    int 0x10 ; call interrupt to set video mode

    ; Set up segments
    mov ax,cs
    mov ds,ax
    mov ax, video_segment
    mov es,ax
    
    ; set RNG state
	mov	ah, 0x00
	int	0x1A		; get clock ticks since midnight - lower bits in dx
	mov	[rng_state], dx

init_level:
    ; Set up level array
    mov bx, level_addr
    mov di, fog_addr
    mov cx,level_size
init_level_loop:
    ; empty char by default
    mov word [bx], empty_char
    mov byte [di], 0 ; fog enable 1 / disable with 0

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

init_tunnel:
    mov bx, (level_addr + 2 * (2*level_width + 2))
    mov cx, 8
    call fill_wall

    mov bx, (level_addr + 2 * (8*level_width + (level_width-3)))
    mov cx, 8
    call fill_wall

    mov ax, horizontal_step
    mov bx, (level_addr + 2 * (8*level_width + 4))
    mov cx, (level_width - 6)
    call fill_wall

    mov bx, (level_addr + 2 * (10*level_width + 2))
    mov cx, (level_width - 6)
    call fill_wall

init_random_houses:
    ; paint random rows of houses or trees or somethings
    ; top part
    mov ax, 6
    mov dx, house_char
    mov bx, level_addr + 2 * (2*level_width + 4)
    mov cx, level_width - 6
    call fill_house
    
    mov bx, level_addr + 2 * (4*level_width + 4)
    call fill_house

    mov bx, level_addr + 2 * (6*level_width + 4)
    call fill_house

    ; bottom part
    mov ax, 8
    add cx, 3 ; trees eat into tunnel a bit, that's fine
    mov dx, tree_char
    mov bx, level_addr + 2 * (12*level_width + 1)
    call fill_house

    mov bx, level_addr + 2 * (13*level_width + 1)
    call fill_house
    
    mov bx, level_addr + 2 * (14*level_width + 1)
    call fill_house

    mov bx, level_addr + 2 * (15*level_width + 1)
    call fill_house

    mov bx, level_addr + 2 * (16*level_width + 1)
    call fill_house

init_entities:
    ; Set player coordinate
    call random_empty_coord
    mov [player_pos],dx
    mov byte [player_addr + current_hp_offset],15
    mov byte [player_addr + max_hp_offset],15
    mov byte [player_addr + type_offset],'@'

    mov cx,num_start_enemies
init_enemies_loop:
    ; make enemy coordinates
    call random_empty_coord

    push cx
    mov cx, level_width
    call xy2offset
    pop cx

    ; get level offset
    shl dx, 1
    mov bx, level_addr
    add bx, dx

    ; calculate enemy's array offset - max_entity_offset*cx + entity_arr
    mov ax, max_entity_offset
    mul cx

    ; store enemy sentinel and offset in level
    mov word [bx], ax
    add word [bx], (enemy_sentinel * 256)
    
    ; store enemy attributes in array
    mov di, ax
    add di, entity_arr
    mov byte [di + current_hp_offset], 3
    mov byte [di + max_hp_offset], 3
    mov byte [di + type_offset], 0xEA

    loop init_enemies_loop
init_fog_clear:
    ; initial fog clear
    mov dx, [player_pos]
    call reveal_fog
render_level:
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
    cmp ah, enemy_sentinel
    jne render_char
render_enemy_type:
    ; if entity, substitute in entity type
    ; al is now the offset in the entity array
    push bx
    movzx bx, al
    add bx, entity_arr + type_offset
    mov al, [bx]
    pop bx
    ; (enemy_sentinel):(enemy type) is now in ax
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
    mov bx, [player_addr + current_hp_offset]
    mov [player_health_str_addr], bx
    mov bx,string
    mov dl,level_width+5
    mov dh,0x05
    call draw_text

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

    ; check for enemy
    cmp byte [bx + 1], enemy_sentinel
    je hit_enemy
    
    cmp word [bx], wall_char
    je hit_wall

    cmp word [bx], house_char
    je hit_wall

    ; passed checks - update position
    mov [player_pos],dx
    call reveal_fog
    jmp render_level

hit_wall:
    ; TODO: set status flag
    jmp render_level

hit_enemy:
    ; get enemy health
    push bx ; save level data pointer
    mov bx, [bx]
    xor bh,bh
    add bx, entity_arr + current_hp_offset

    ; dec enemy health and check
    dec byte [bx]
    cmp byte [bx], 0
    pop bx
    jne hit_basic_enemy_player_hit
hit_basic_enemy_enemy_died:
    mov word [bx], empty_char
hit_basic_enemy_player_hit:
    ; dec player health and check
    dec byte [player_addr + current_hp_offset]
    cmp byte [player_addr + current_hp_offset], 0

    je do_exit

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

offset2xy:
    ; DX contains the offset -> store as dh=y, dl=x
    push ax
    push bx

    mov ax, dx
    xor dx, dx
    mov bx, level_width
    div bx

    ; Remainder (x) is already in dx, and small enough to fit in dl
    ; move quotient (y) to dh
    mov dh, al

    pop bx
    pop ax

    ret

reveal_fog:
    ; take xy value (dh=y, dl=x) and unset fog array 2 squares around it
    ; clobbers most registers

    ; use as counter for number of fogs revealed
    xor bh,bh

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

fog_heal:
    ; heal all entities
    mov cx, num_start_enemies+1
    mov di, entity_arr + current_hp_offset
fog_heal_loop:
    ; increase current hp by amount of fog revealed
    add byte [di], bh
    push bx

    ; set up comparison of current vs max hp
    mov bx, [di]
    cmp bh, bl
    jg heal_next
    mov byte [di], bh ; reset current hp to max hp
heal_next:
    pop bx
    add di, max_entity_offset

    loop fog_heal_loop
heal_ret:
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
    mov si,dx
    add si,fog_addr
    add bh, [si]
    mov byte [si], 0

    ; check contents of level at location
    shl dx,1 ; level array has 2 byte offsets
    mov di,dx
    add di,level_addr

    pop cx
    pop dx
    ; re-add offset so we have it for the next loop
    add dh,ah
    add dl,al
    
    cmp word [di], empty_char
    jne end_reveal_fog_line
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

fill_house:
    ; ax has p(fill) out of 10
    ; bx has wall start index
    ; cx has length
    ; dx has char
    push cx
fill_house_loop:
    push dx
    push bx
    push ax
    mov bx, 0x0a
    call rng_lcg
    pop ax
    cmp dx, ax
    pop bx
    pop dx
    jge skip
    mov word [bx], dx
skip:
    add bx, 2

    loop fill_house_loop
    pop cx
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

rng_lcg:
    ; Generate a random value lying in [0, bx) and store in dx
    push ax
    push bx
    mov ax, [rng_state]
    mov bx, rng_a
    mul bx ; dx:ax = ax * bx

    add ax, rng_c
    adc dx, 0 ; add carry bit to dx

    mov bx, rng_m
    div bx ; ax = (dx:ax) / bx, dx = (dx:ax) % bx

    ; remainder becomes new state
    mov [rng_state], dx

    ; Truncate DX to lie between 0 and upper_bound-1
    mov ax, dx

    xor dx,dx ; zero out dx so that we are just dividing ax and not (dx:ax)

    pop bx
    div bx  ; AX = (AX) / BX, DX = (AX) % BX

    pop ax
    ret

random_empty_coord:
    mov bx, level_size
    call rng_lcg
    mov bx, dx

    ; pointer into level - 2 byte offset + level_addr
    shl bx,1
    add bx,level_addr

    ; if wall / house / enemy, try again
    ; if empty / tree, we're good

    cmp word [bx], empty_char
    je found_empty_coord ; exit

    cmp word [bx], tree_char
    je found_empty_coord ; exit

    jmp random_empty_coord ; try again
found_empty_coord:
    call offset2xy

    ret

section .data
string:
    db "HP:   ", 0
