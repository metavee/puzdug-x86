org 0x0100

player_pos: equ 0x0200      ; 2 bytes for player position

level_dim: equ 25
level_size: equ 400         ; level_dim^2

video_segment: equ 0xB800   ; Segment address for video memory
row_width: equ 80           ; Width of the screen in characters

; https://www.lookuptables.com/text/extended-ascii-table
; https://www.rapidtables.com/convert/number/decimal-to-hex.html?x=247
wall_char: equ 0x04b2 ; black bg, red fg, heavy texture ▓
empty_char: equ 0x07b0 ; black bg, grey fg, light texture ░
fog_char: equ 0x07f7 ; black bg, grey fg, almost equal ≈

start:
    mov ax,0x0002 ; set video mode to color text
    int 0x10 ; call interrupt to set video mode

    ; Set up segments
    mov ax, video_segment
    mov ds,ax
    mov es,ax

init_board:
    cld ; clear direction flag - di will increment
    xor di,di ; set di to 0

    mov cx,level_size
    xor dx,dx
init_board_loop:
    ; store empty_char everywhere on screen
    mov ax, empty_char
    stosw

    ; newline logic
    inc dx
    cmp dx, level_dim
    jl continue_board_loop ; jump if we are not yet at newline
    add di, (row_width - level_dim) * 2
    xor dx, dx

continue_board_loop:
    loop init_board_loop          ; Decrement CX, if CX != 0, loop back

    ; press any key to exit
    call read_keyboard

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
