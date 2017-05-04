s_insert_drive db "Missing or invalid argument. Specify Drive to Boot (eg: boot 0 | 1 | 80 | 81)",10,0

ttyBoot:

    mov     ax,     [tty_params_address]

    cmp     ax,     0x0000                 ; check if drive argument is found
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
        mov     ax,     s_insert_drive
        call    print
        jmp     interpreterTTY.done
        ;-----------------------------------------------------------------------
    .boot:
        ; prepare to read Stage2 from disk image and load in 0x0000:0x7E00
        mov     dl,     al              ; Drive (user input: arg1)
        mov     ax,     0x0000          ; Destination segment
        mov     es,     ax              ; set Destination segment
        mov     bx,     0x7C00          ; Destination offset.
        mov     al,     1               ; Number of sectors to load
        mov     dh,     0               ; Head 0

        mov     ch,     0               ; Cylinder 0,
        mov     cl,     1               ; Start in Sector 1
        call    readDriveSectors
        jnc     .success                ; Ready!

        ;error
        mov     ax,     s_FlDiskReadErr ; print error message
        call    print
        jmp     interpreterTTY.done
    .success:                                ;relative
        xor ax, ax
        xor bx, bx
        xor cx, cx
        xor dx, dx

        jmp 0x0000:0x7C00




readDriveSectors:
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
