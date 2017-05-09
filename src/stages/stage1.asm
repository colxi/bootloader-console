org 0x7C00  		;Boot loader start address
use16 				;force 16 bits binary

;-------------------------------------------------------------------------------
;
; 	BOOTLOADER : STAGE 1
;
;-------------------------------------------------------------------------------

; jump to entry point
jmp main
nop

; Use FASM preprocessing to calculate Sector2 Size
; and calculate thr number of disk sectors to be loaded.
STAGE2_SIZE 		   	=  (___stage2_end_offset - ___stage2_start_offset)
STAGE2_SECTORS_COUNT   	=  ( ( STAGE2_SIZE - ( STAGE2_SIZE mod 512) ) / 512 )+1

STAGE2_SEGMENT		   	EQU  0x0000
STAGE2_OFFSET		   	EQU  0x7E00

VIDEO_MODE 			   	EQU 	0x03 	; text mode
VIDEO_COLORS 		   	EQU  0x17 	; grey over blue background
VIDEO_COLS 	 		   	EQU  80
VIDEO_ROWS 	 		   	EQU  25

s_name      	 db    	'TTY-BOOT',  10, 0
s_stage1Loaded 	 db    	'Stage 1 loaded at 0x0000:0x7C00 (512 bytes)' , 10, 0
s_ReadingDisk	 db    	'Read Stage 2 from Disk (sector 2)' , 10, 0
s_stage2Loaded_1 db    	'Stage 2 Loaded at 0x0000:0x7E00 (' , 0
s_stage2Loaded_2 db    	' bytes + sector padding)' , 10, 0
s_FlDiskReadErr  db    	'Disk Read ERR' , 10, 0
s_bootl_ready    db    	'Ready!', 10, 0
EMPTY_STRING  	 db 	'', 0


;;******************************************************************************
 ;
 ; REAL ENTRY POINT!
 ;
 ;******************************************************************************
main:
	xor 	ax, 	ax
	xor 	bx, 	bx
	xor 	cx, 	cx
	xor 	dx, 	dx

	; set text video mode
	mov 	ax, 	VIDEO_MODE
	int 	0x10

	call 	clearScreen
	call 	resetDrive

	cli         					; Disable interrupts

	; Data Segment
	mov 	ax, 	0x0000
	mov 	ds, 	ax 				; set data segment to 0x00

	; Stack Segment
	mov 	ax, 	0x8000
	mov 	ss, 	ax 				; Stack Segment the top at ( 0x8000:0x00 )

	; Stack Pointer Offset
	mov 	sp, 	0x0000  		; Bottom of stack


 	sti 							; Enable Interrupts again

 	;--- info output block
	mov ax, s_name
	call print
	mov ax, s_stage1Loaded
	call print
	mov ax, s_ReadingDisk
	call print

	; prepare to read Stage2 from disk image and load in 0x0000:0x7E00
	mov 	ax, 	STAGE2_SEGMENT	; Destination segment
	mov 	es, 	ax 				; set Destination segment
	mov  	bx, 	STAGE2_OFFSET   ; Destination offset.
	mov  	al, 	STAGE2_SECTORS_COUNT  ; Number of sectors to load
	mov  	dl, 	0     	 		; Drive 0
	mov  	dh, 	0 	        	; Head 0
	mov  	ch, 	0       		; Cylinder 0,
	mov  	cl, 	2 		    	; Start in Sector 2
	call 	readSectors
	jnc  	.success        		; Ready!

	; if carry flag set, either the disk system wouldn't reset, or we exceeded
	; our maximum attempts and the disk is probably damaged
	; Asume error happened on DISK reading...
	mov 	ax, 	s_FlDiskReadErr ; print error message
	call 	print
	.halt:
		jmp 	.halt 				; halt system
	;---------------------------------------------------------------------------
	.success:
		;--- info output block
	    mov     ax,     s_stage2Loaded_1
	    call    print

		jmp 	STAGE2_SEGMENT:STAGE2_OFFSET 	; READY! jump to stage2 2
	;---------------------------------------------------------------------------

;**************************************************
;
; ESSENTIAL I/O PROCEDURES
;
;**************************************************


;;******************************************************************************
 ;
 ;  readSectors()
 ;  Reads sectors from disk using BIOS services and stores them in requested
 ;  memory adress
 ;
 ;  Input       AL = Number of sectors to read (must be nonzero)
 ;              BX = Destination adress (ES:BX , data buffer)
 ;              CH = Low eight bits of cylinder number
 ;              CL = [7:6] xx------ Hight 2 bits of cylinder num. Hard disk only
 ;                   [5:0] --xxxxxx Sector number (1-63)
 ;                   ( When setted, CL[7:6]+CH will be used as cylinder number )
 ;              DL = Drive number (bit 7, set for hard disk)
 ;              DH = Head number
 ;
 ;  Output      CF = 0 (suces) | 1 (failure)
 ;
 ;  Destroy     AX
 ;
 ;;**************************************************
readSectors:
    xor     ah,     ah      ; ...else, reset disk system (int 0x13, ah=0x00)
    int     0x13            ; (moves back to first sector)

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


; reset disk drive , go to the first Sector on disk.
resetDrive:
	mov 	ah,		0x00
	mov 	dl,		0
	int 	0x13
	RET

include 'lib/stdio.asm'

; pad with zeroes sector one -2 (magic bytes lenght)
times ((512 - 2) - ($ - $$)) db 0x00
; Magic bytes.
dw 0xAA55


