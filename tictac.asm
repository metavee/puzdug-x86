    org 0x0100

board:      equ 0x0300

start:
    mov bx,board
    mov cx,9        ; 9 squares for loop
    mov al,'1'      ; store '1' char
b09:
    mov [bx],al     ; save al into board
    inc al          ; increment al '1' to '2' etc.
    inc bx        ; move to next board square
    loop b09    ; loop 9 times

b10:
    call show_board
    call find_line
    call find_tie
    
    ; place X and O
    call get_movement
    mov byte [bx],'X' ; put X into square
    call show_board
    call find_line
    call find_tie

    call get_movement
    mov byte [bx],'O' ; put O into square

    jmp b10

get_movement:
    call read_keyboard
    cmp al,0x1b ; check for escape key
    je do_exit

    sub al,0x31 ; convert ascii to number
    jc get_movement ; if less than 1, try again

    cmp al,0x09
    jnc get_movement ; if greater than 9, try again

    cbw ; convert al to ax
    
    mov bx,board
    add bx,ax ; move to correct square
    mov al,[bx] ; get current value
    cmp al,0x40 ; check if square is empty - if it's greater than 1-9
    jnc get_movement ; if not, try again

    call show_crlf ; we accept input, so move to next line
    ret

do_exit:
    int 0x20

show_board:
    mov bx,board
    call show_row
    call show_div
    
    mov bx,board+3
    call show_row
    call show_div

    mov bx,board+6
    jmp show_row

show_row:
    call show_square

    mov al,0x7c
    call display_letter
    call show_square

    mov al,0x7c
    call display_letter
    call show_square
show_crlf:
    mov al,0x0d
    call display_letter
    mov al,0x0a
    jmp display_letter

show_div:
    mov al,0x2d
    call display_letter

    mov al,0x2b
    call display_letter

    mov al,0x2d
    call display_letter

    mov al,0x2b
    call display_letter

    mov al,0x2d
    call display_letter

    jmp show_crlf

show_square:
    mov al,[bx]
    inc bx
    jmp display_letter

; store a square in al and check equality with other lines
find_line:
    ; first horizontal row
    mov al,[board]
    cmp al,[board+1]
    jne b01
    cmp al,[board+2]
    je won
b01:
    ; leftmost column
    cmp al,[board+3]
    jne b04
    cmp al,[board+6]
    je won
b04:
    ; first diagonal
    cmp al,[board+4]
    jne b05
    cmp al,[board+8]
    je won
b05:
    ; second row
    mov al,[board+3]
    cmp al,[board+4]
    jne b02
    cmp al,[board+5]
    je won
b02:
    ; third row
    mov al,[board+6]
    cmp al,[board+7]
    jne b03
    cmp al,[board+8]
    je won
b03:
    ; second column
    mov al,[board+1]
    cmp al,[board+4]
    jne b06
    cmp al,[board+7]
    je won
b06:
    ; third column
    mov al,[board+2]
    cmp al,[board+5]
    jne b07
    cmp al,[board+8]
    je won
b07:
    ; second diagonal
    cmp al,[board+4]
    jne b08
    cmp al,[board+6]
    je won
b08:
    ret

won:
    ; al still has the winning letter
    call display_letter
    mov al,' '
    call display_letter
    mov al,'w'
    call display_letter
    mov al,'o'
    call display_letter
    mov al,'n'
    call display_letter

    int 0x20

find_tie:
    mov bx,board
    mov cx,9
    mov al,'1'
tie_loop:
    cmp [bx],al
    je tie_not
    inc al
    inc bx
    loop tie_loop
tie:
    mov al,'t'
    call display_letter
    mov al,'i'
    call display_letter
    mov al,'e'
    call display_letter
    int 0x20
tie_not:
    ret
