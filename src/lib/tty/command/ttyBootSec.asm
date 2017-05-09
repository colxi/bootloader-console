BUFFER_ASCII_SIZE = 16
s_def_drive db "Missing or invalid argument. Specify Drive to Boot (eg: boot 0 | 1 | 80 | 81)",10,0
s_buffer_ascii: times BUFFER_ASCII_SIZE db 0, 0

ttyBootsec:
    mov     ax,     [tty_params_address]

    cmp     ax,     0x0000                  ; check if drive argument is found
    je      .err                            ; if not : err

    ; validate if Drive to boot is supported
    call    atoi
    cmp     ax,     0
    je      .boot
    cmp     ax,     1
    je      .boot
    cmp     ax,     80
    je      .boot
    cmp     ax,     81
    je      .boot
    ;---------------------------------------------------------------------------
    .err:
        mov     ax,     s_def_drive
        call    print
        jmp     interpreterTTY.done
        ;-----------------------------------------------------------------------
    .boot:
        ; prepare to read Stage2 from disk image and load in 0x0000:0x7E00
        mov     dl,     al              ; Drive (user input: arg1)
        mov     ax,     0x0000          ; Destination segment
        mov     es,     ax              ; set Destination segment
        mov     bx,     tty_buffer      ; Destination offset.
        mov     al,     1               ; Number of sectors to load
        mov     dh,     0               ; Head 0

        mov     ch,     0               ; Cylinder 0,
        mov     cl,     1               ; Start in Sector 1
        call    readDriveSectors2
        jnc     .success                ; Ready!

        ;error
        mov     ax,     s_FlDiskReadErr ; print error message
        call    print
        jmp     interpreterTTY.done
    .success:
        ;print data
        mov     bx,     0               ; init counter for hex chars in each row
        mov     di,     0               ; pointer to ASCII representation buffer
        mov     si,     tty_buffer      ; pointer to current sector byte
    .nextByte:
        mov     al,     byte [si]       ;

        mov     di,     s_buffer_ascii
        add     di,     word bx

        push    ax
        mov     ah , "."
        call    maskNotPrintable
        mov     [di], byte al
        pop     ax

        call hextoa
        call print
        mov al, " "
        call printChar
        inc     si
        cmp si, tty_buffer + 512
        je .done
        inc bl
        cmp bl, BUFFER_ASCII_SIZE
        jne .nextByte
        mov ax, s_buffer_ascii
        call print
        call printLF
        mov bl, 0
        jmp .nextByte
        ;-----------------------------------------------------------------------
        .done:
        mov ax, s_buffer_ascii
        call print
        call printLF
        jmp interpreterTTY.done


readDriveSectors2:
    mov     si,     3           ; Maximum attempts - 1
    .read:
        mov     ah,     0x02    ; read sectors into memory (int 0x13, ah = 0x02)
        int     0x13            ; call interrupt
        jnc     .done           ; If read succeeded Finish
        dec     si              ; ...if not, decrement attempts counter
        jc      .done           ; If maximum attempts exceeded (CF=1) Exit
        xor     ah,     ah      ; ...else, reset disk system (int 0x13, ah=0x00)
        int     0x13            ; (moves back to first sector)
        jnc     .read           ; If reset succeeded, Retry ( otherwise Finish )
    .done:
        ; TO DO: Status code return
        ; AH should contain status of previous operation
        ; ...but some BIOS return it in AL.
        ; Satus Codes Table ref: http://www.ctyme.com/intr/rb-0606.htm#Table234
        xor     ax,     ax
        RET
