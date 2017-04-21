org 0x7E00  ;Boot loader start address
use16

;-------------------------------------------------------------------------------
;
; 	BOOTLOADER : STAGE 2
;
;-------------------------------------------------------------------------------

bootloader_Stage2:

	xor ax, ax
	mov es, ax

	; Data Segment
	mov 	ds, 	ax 				; set data segment to 0x00

    ; set cursor
    mov dh, 1
    mov dl, 0
    call setCursor

    ; output: both stages loaded!
    mov ax, s_stagesLoaded
    call print

    ; output: title
    mov ax, s_title
    call print


    ; output: BIOS FLAGS
    mov     ax,     s_BIOS
    call    print

    mov     al,     '['
    call    printChar

    int     11h                 ; get BIOS hardware flag bytes
    mov     dx,     ax          ; temporally store bytes in DX

    mov     al,     dh
    call    printByteBin
    mov     al,     ':'
    call    printChar
    mov     al,     dl
    call    printByteBin
    mov     al,     ']'
    call    printChar

    call    printLF
    mov     ax,     s_floppy
    call    print

    mov     ah,     11000000b
    mov     al,     dl
    mov     cl,     6
    call    readFlag
    add al,1


    call    printLF
    mov     ax,     s_floppyIn
    call    print




    mov al, ">"
    call printChar

    call listenKeyboard
    RET


s_stagesLoaded  db 		'1st and 2nd Bootloader Stages Loaded!' , 10, 0
s_title         db      'vBootloader : a 16-bit x86 assembly verbose bootloader', 10, 10, 0
s_BIOS          db      '[+] Reading BIOS Hardware detection FLAGS...', 0 ;
s_floppy        db      '    - Floppy Devices     : ',  0
s_floppyIn      db      '    - Floppy Inserted    : ',  0
s_videoMode     db      '    - Initial video mode : ',  0
s_MatchCo       db      '    - Math coprocessor   : ',  0


