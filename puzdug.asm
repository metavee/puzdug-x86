org 0x0100

player_pos: equ 0x0200      ; 2 bytes for player position
level: equ 0x0300           ; Start of level array in memory
board_size: equ 400         ; Size of the board

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

    cld ; clear direction flag - di will increment
    xor di,di ; set di to 0

init_board:
    mov ax, fog_char
    stosw

    ; Initialize player position
    mov word [player_pos], 0
; wipe_level:
;     mov si, level           ; SI points to the level array
;     mov cx, board_size
;     mov al, '.'             ; Fill with dots
; wipe_loop:
;     stosb                   ; Store AL at DS:SI and increment SI
;     loop wipe_loop          ; Decrement CX, if CX != 0, loop back

; show_board:
;     mov si, level           ; SI points to the level array
;     xor di, di              ; DI starts at 0 within the video memory segment
;     mov cx, board_size      ; CX is the number of characters to display

; show_loop:
;     ; Check if we are at player_pos and print the player character
;     mov bx, 400
;     sub bx, [player_pos]
;     cmp cx, bx
;     jne board_letter
;     mov al, '@'
;     jmp board_write

; board_letter:
;     lodsb                   ; Load byte at DS:SI into AL and increment SI

; board_write:
;     stosw                   ; Write AL to video memory at ES:DI and increment DI by 2
;     mov byte [di-1], 0x07   ; Set attribute byte (white on black)

;     inc dx
;     ; if dx >= 20 then reset column counter and move to next line
;     cmp dx, 20
;     jl continue_loop

;     ; Reset for new row
;     add di, (row_width - 20) * 2
;     xor dx, dx

; continue_loop:
;     loop show_loop          ; Decrement CX, if CX != 0, loop back

do_exit:
    int 0x20                ; Terminate the program

; times 510-($-$$) db 0       ; Fill the rest of the boot sector with zeroes
; dw 0xAA55                   ; Boot sector signature
