    int 0x20 ; exit

; display letter contained in AL
display_letter:
    ; save registers
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ah,0x0e ; set AH for terminal output
    mov bx,0x000f ; set BX for page zero, color white
    int 0x10 ; call interrupt to display character

    ; restore registers
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret ; returns to caller

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


; display value of ax as decimal
display_number:
    mov dx,0
    mov cx,10
    div cx ; ax = dx:ax / cx
    push dx

    cmp ax,0
    je display_number_1
    call display_number

display_number_1:
    pop ax
    add al,'0'
    call display_letter
    ret
