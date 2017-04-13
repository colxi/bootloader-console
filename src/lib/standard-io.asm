use16

s_HexMap        db      '0123456789ABCDEF'

;;--------------------------------------------
 ; Routine: output string in AL to screen
 ;--------------------------------------------
print:
    push    ax

    mov     si,     ax                 ; copt input address to Stack index
    .nextChar:
        lodsb                           ; load string byte: retrieves a byte of data from the location pointed
                                        ; to by SI, and stores it in AL (the lower byte of AX)
        cmp     al,     0
        je      .done                   ; If char is zero, end of string detected!
        call    printChar               ; Otherwise, print it
        jmp     .nextChar               ; and go with next char
    .done:
        pop     ax

        RET



;;**************************************************
 ;
 ;  printChar () - Prints a character to screen
 ;  + input:
 ;      AL = Character to print
 ;  + output:
 ;      (none)
 ;  + destroy:
 ;      (none)
 ;
 ;**************************************************
printChar:
    ; ARGUMENTS for  BIOS interrupt 0x10 call
    ;INT 0x10 is a BIOS video interrupt. All the video related calls are made through this interrupt.
    ;To use this interrupt we need to set the values of some register.
    ;AL = ASCII value of character to display
    ;AH = 0x0E ;Teletype mode (This will tell bios that we want to print one character on screen)
    ;BL = Text Attribute (This will be the fore ground and background color
    ;of character to be displayed. 0x07 in our case.)
    ;BH = Page Number (0x00 for most of the cases)
    ;Once all the registers all filled with appropriate value, we can call interrupt.
    push ax
    push bx
    push cx
    push dx

    cmp al,10
    je  .char_LF

    mov ah, 0x0E    ; 0x0E = single character BIOS print service
    mov bh, 0x00    ; Page no. 0
    mov bl, 0x07    ; Text attribute 0x07 is lightgrey font on black background
    int 0x10        ; Call BIOS video interrupt


    .done:
        pop dx
        pop cx
        pop bx
        pop ax

        RET

    .char_LF:
        ;call    printLF
        jmp     .done




listenKeyboard:
                xor ax, ax      ; zero ax register to clear previous keypress values

                int 16h         ; KEYBOARD - READ CHAR FROM BUFFER, WAIT IF EMPTY
                call printChar      ; Return: AH = scan code, AL = character

                jmp listenKeyboard
                RET

;;**************************************************
 ;
 ;  setCursor () - Sets Cursor position
 ;  + input :
 ;      DH = Row
 ;      DL = Column
 ;  + output:
 ;      DH = Row
 ;      DL = Column
 ;
 ;**************************************************
setCursor:
    push ax
    push bx

    mov ah, 02h     ; 0x02 set cursor position.
    mov bh, 00h     ; Page no. 0
    int 10h

    pop bx
    pop ax
    RET

;**************************************************
;
;   getCursor () - Gets Cursor position
;   + input :
;       (none)
;   + output :
;       DH = Row
;       DL = Column
;
;**************************************************
getCursor:
    push ax
    push bx

    mov ah, 03h     ; 0x03 get cursor position.
    mov bh, 00h     ; Page no. 0
    int 10h

    pop bx
    pop ax
    RET




;;***************************************************
 ;
 ;  printByteBin () - Prints a Binary representation of a Byte
 ;  + input:
 ;      AL = Byte to print
 ;  + output:
 ;      (none)
 ;  + destroy:
 ;      (none)
 ;
 ;**************************************************
printByteBin:
    push    ax
    push    bx
    push    cx

    mov     bl,     al              ; Clone value to operate wit it
    mov     cl,     7               ; initialize counter
    .nextBit:
        mov     al,     bl          ; clone BYTE value to operate on it
        mov     dh,     00000001b   ; init mask
        shl     dh,     cl          ; shif MASK c times left to match current bit
        and     al,     dh          ; aply MASK on BYTE to reset unwanted bits
        shr     al,     cl          ; shift BYTE c times right to get absolute 0 or 1
        or      al,     00110000b   ; Move in the ascii table  the resulting value
        call    printChar           ; Print the value
        sub     cl,     1           ; decrease bit curent counter by 1
        cmp     cl,     0           ; Compare Counter with 0
        jge     .nextBit            ; If counter >= 0, jump to nextBit

    pop     cx
    pop     bx
    pop     ax
    RET


printByteHex:
    push    ax
    push    bx
    push    dx

    mov     si,     s_HexMap            ; Pointer to hex-character table
    mov     dl,     al
    mov     bh,     00000000b

    mov     bl,     dl                  ; BX = argument AX
    shr     bl,     4                   ; Isolate high nibble (i.e. 4 bits)
    mov     al,     [si+bx]             ; Read hex-character from the table
    call    printChar

    mov     bl,     dl                  ; BX = argument AX (just to be on the safe side)
    and     bl,     00001111b           ; Isolate low nibble (i.e. 4 bits)
    mov     al,     [si+bx]             ; Read hex-character from the table
    call    printChar

    pop     dx
    pop     bx
    pop     ax
    RET


printLF:
    call getCursor
    add dh,1
    mov dl, 0
    call setCursor
    RET





readFlag:
    mov cl, 0 ; counter 0

    .nextBit:
        mov  dl, ah
        cmp cl, 8
        je .done
        shr     dl,     cl
        and dl , 00000001b
        cmp dl, 1
        je  .done
        add cl, 1
        jmp .nextBit

    .done:
        add al, ah  ; apply mask on byte
        shr     al, cl
        RET




clearScreen:
; clear screen (CLS)
    mov ax, 0x0600  ;ax 06(es un recorrido), al 00(pantalla completa)
    mov bh, 0x71       ;fondo blanco(7), sobre azul(1)
    mov cx, 0x0000     ;es la esquina superior izquierda reglon: columna
    mov dx, 0x184F     ;es la esquina inferior derecha reglon: columna
    int 0x10       ;interrupcion que llama al BIOS
    RET

