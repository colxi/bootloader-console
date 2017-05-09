;-------------------------------------------------------------------------------
;
;  Name           : string-manipulation.asm
;
;  Description    : 16BIT FASM assembly minimal library focused into provide
;                   the essential resources, to string manipulation
;
;                   Contents:
;                   strcmp | strlen | strchr | trim | ltrim | rtrim
;                   To do:
;                   toupper | tolower | strtoupper | strtolower
;
;  Version        : 1.1
;  Created        : 27/03/2017
;  Author         : colxi
;
;-------------------------------------------------------------------------------



;;******************************************************************************
 ; Routine: output string in AX to screen
 ;**************************************************
print:
    pushf
    push    si

    cld                                 ; CLear Direction flag. Direction:ASC
    mov     si,     ax                  ; copy input address to Source Index
    .nextChar:
        lodsb                           ; load string byte: retrieves a byte of data from the location pointed
                                        ; to by SI, and stores it in AL (the lower byte of AX)
        cmp     al,     0
        je      .done                   ; If char is zero, end of string detected!
        call    printChar               ; Otherwise, print it
        jmp     .nextChar               ; and go with next char
    .done:
        pop     si
        popf
        RET

;;******************************************************************************
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
    pusha

    cmp     al,     10          ; if ENTER character, jump to new Line
    je      .char_LF

    mov     ah,     0x0E        ; 0x0E = single character BIOS print service
    mov     bh,     0x00        ; Page no. 0
    mov     bl,     VIDEO_COLORS; Text attribute colors
    int     0x10                ; Call BIOS video interrupt

    cmp     al,     8           ; if BACKSPACE called, remove characgter
    je      .char_backspace

    jmp     .done
    ;---------------------------------------------------------------------------
    .char_backspace:
        mov     ah,     0x09        ; 0x0E = print without moving cursor
        mov     al,     0x00        ; NULL character
        mov     bh,     0x00        ; Page no. 0
        mov     bl,     VIDEO_COLORS; Text attribute 0x07 is lightgrey font on black background
        mov     cx,     0x01        ; print 1 time the character
        int     0x10                ; Call BIOS video interrupt
        jmp     .done
    ;---------------------------------------------------------------------------
    .char_LF:
        call    printLF
        jmp     .done
    ;---------------------------------------------------------------------------
    .done:
        popa

        RET




;;******************************************************************************
 ;
 ;
 ;
 ;******************************************************************************
printLF:
    push dx

    call getCursor
    add dh,1
    mov dl, 0
    call setCursor

    pop dx
    RET

;;******************************************************************************
 ;  setCursor () - Sets Cursor position
 ;  + input :
 ;      DH = Row
 ;      DL = Column
 ;  + output:
 ;      DH = Row
 ;      DL = Column
 ;
 ;******************************************************************************
setCursor:
    pusha

    mov ah, 02h     ; 0x02 set cursor position.
    mov bh, 00h     ; Page no. 0
    int 10h

    popa
    RET

;;******************************************************************************
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
    push ax         ; prevent int10h destroy register
    push bx         ; prevent procedure destroy register
    push cx         ; prevent int10h destroy register

    mov ah, 03h     ; 0x03 get cursor position.
    mov bh, 00h     ; Page no. 0
    int 10h

    pop cx
    pop bx
    pop ax
    RET

clearScreen:
    pusha

    ; clear screen (CLS)
    mov ah, 0x06             ; Clear/Scroll Screen Up
    mov al, 00               ; Number of lines to scroll (0=clear entire window)
    mov bh, VIDEO_COLORS     ; Colors
    mov cx, 0x0000           ; Row&Col numbers of upper left corner
    mov dh, VIDEO_ROWS-1     ; Lower Row number
    mov dl, VIDEO_COLS-1     ; Most Right Col number
    int 0x10                 ; BIOS Video Services

    mov dx , 0x0000          ; mov vursor to up left on screen
    call setCursor

    popa
    RET
