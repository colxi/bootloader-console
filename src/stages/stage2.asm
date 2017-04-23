use16
;-------------------------------------------------------------------------------
;
;   BOOTLOADER : STAGE 2
;
;-------------------------------------------------------------------------------

___stage2_start_offset:
bootloader_Stage2:
    ; output info block
    mov ax, s_bootl_ready
    call print

    call initTTY;

    RET


include 'lib/tty.asm'
___stage2_end_offset:

; Pad image to multiple size of 512 bytes (sector align).
times 512 + (  STAGE2_SECTORS_COUNT * 512 ) - ($ - $$) db 0x00

