;----------------------------------------------------------------------------
;
;  Name           : data-type-convert.asm
;
;  Description    : 16BIT FASM assembly minimal library focused into provide
;                   the essential resources, to convert byte values, to diferent
;                   and equivalent ASCII representations.
;
;                   Contents:
;                   itoa | uitoa | hextoa | bintoa
;
;  Version        : 1.0
;  Created        : 24/03/2017
;  Author         : colxi
;
;---------------------------------------------------------------------------


use16


;;**************************************************
 ;
 ;   itoa()  -  Returns the ASCII Decimal representation of
 ;              SIGNED values stored in AX (16 bits).
 ;              Note: Will perform a call to uitoa
 ;   + input :
 ;       AX = Signed Integer to convert
 ;   + output :
 ;       AX = Pointer to string in memory
 ;
 ;**************************************************
itoa:
    test    ax,     ax              ; check if is negative
    js      .negative
        call    uitoa               ; not negative! call uitoa
        RET
    .negative:
        neg     ax                  ; convert to positive
        call    uitoa               ; call uitoa to ASCII conversion
        dec     si                  ; decrement si pointer by 1
                                    ; -SI was set in the previous uitoa() call-
        mov     [si],   byte "-"    ; insert negative symbol before number
        mov     ax,     si          ; update updated SI value into AX
        RET



;;**************************************************
 ;
 ;   uitoa()  - Returns the ASCII Decimal representation of
 ;              UNSIGNED values stored in AX (16 bits).
 ;              Note: Algorithm moves in decending order,
 ;              from las digit, to first digit.
 ;   + input :
 ;       AX = Unsigned integer to convert
 ;   + output :
 ;       AX = Pointer to string in memory
 ;
 ;**************************************************
uitoa:
    push bx
    push dx

    lea     si,     [.buffer+6]     ; set pointer to last byte in buffer
    mov     bx,     10              ; set divider
    .nextDigit:
        xor     dx,     dx          ; clear dx before dividing dx:ax by bx
        div     bx                  ; divide ax/10
        add     dx,     48          ; add 48 to remainder to get ASCII tabl char
        dec     si                  ; move buffr pointer backwadrs
        mov     [si],   dl          ; set char in buffer
        cmp     ax,     0
        jz      .done               ; end when ax reach 0
        jmp     .nextDigit          ; else... get next digit
    .done:
        mov     ax,     si          ; store buffer pointer in ax

        pop dx
        pop bx
        RET
    .buffer: times 6 db 0,0         ; 16bit integer max length=5 + null
                                    ; extra byte is added to fit thr negative
                                    ; symbol (-) when processing calls from
                                    ; ITOA proc and handñing negative numbers


;;**************************************************
 ;
 ;   hextoa() - Returns the ASCII Hexadecimal representation
 ;              of the byte stored in AL.
 ;   + input :
 ;       AL = Byte to convert
 ;   + output :
 ;       AX = Pointer to string in memory
 ;
;**************************************************
hextoa:
    push    bx
    push    cx
    push    dx

    mov     si,     .hexMap         ; Pointer to hex-character table
    xor     bh,     bh              ; clear BH register

    mov     bl,     al              ; copy input value
    shr     bl,     4               ; shiftR to get high nibble (first 4 bits)
    mov     ch,     [si+bx]         ; Read hex-character from the table

    mov     bl,     al              ; copy input value
    and     bl,     00001111b       ; Mask byte to get low nibble (last 4 bits)
    mov     cl,     [si+bx]         ; Read hex-character from the table

    mov     [.buffer],   cx         ; save result to char buffer
    mov     ax,     .buffer         ; store in AX address to buffer

    pop     dx
    pop     cx
    pop     bx
    RET
    .buffer:    times 2 db 0, 0     ; 2 bytes, one for each character + null
    .hexMap:    db    '0123456789ABCDEF'; ASCII mapping



;;**************************************************
 ;
 ;   hextoa() - Returns the ASCII Binary representation
 ;              of the byte stored in AL.
 ;   + input :
 ;       AL = Byte to convert
 ;   + output :
 ;       AX = Pointer to string in memory
 ;
;**************************************************
bintoa:
    push    bx
    push    cx

    mov     cl,     7               ; initialize counter
    lea     si,     [.buffer]       ; set pointer to buffer
    .nextBit:
        mov     bl,     al          ; clone BYTE value to operate on it
        mov     bh,     00000001b   ; init mask
        shl     bh,     cl          ; shifL MASK c times to match current bit
        and     bl,     bh          ; aply MASK on BYTE to reset unwanted bits
        shr     bl,     cl          ; shiftR BYTE c times to get absolute 0 or 1
        or      bl,     00110000b   ; Point the rsulting char in Ascii table
        mov     [si],   bl          ; set char in buffer
        inc     si                  ; increment buffer pointer position
        sub     cl,     1           ; decrease bit current counter by 1
        cmp     cl,     0           ; Compare Counter with 0
        jge     .nextBit            ; If counter >= 0, jump to nextBit

    mov     ax,     .buffer         ; store buffer pointer in ax

    pop     cx
    pop     bx
    RET
    .buffer:    times   8 db 0,0    ; 8 bytes, one for each bit  + null

