org 0x7C00  		;Boot loader start address
use16 				;force 16 bits binary


; Memory Mapping (x86)
; ------------------------------------------------------------------------------
; 0x00000000 - 0x000003FF  1 KiB  		  IVT (Interrupt Vector Table)
; 0x00000400 - 0x000004FF  256 bytes      BDA (BIOS data area)
; 0x00000500 - 0x00007BFF  30 KiB aprox   FREE MEMORY
; 0x00007C00 - 0x00007DFF  512 bytes 	  FREE MEMORY (*)   <- BootLoader Stage1
; 0x00007E00 - 0x0007FFFF  480.5 KiB 	  FREE MEMORY (**)  <- Bootloader Stage2
; 0x00080000 - 0x0009FBFF  120 KiB aprox  FREE MEMORY (***) <- Bootloader Stack
; 0x0009FC00 - 0x0009FFFF  1 KiB RAM 	  EBDA (Extended BIOS Data Area)
; 0x000A0000 - 0x000BFFFF  				  Video RAM (VRAM) Memory
; 0x000B0000 - 0x000B7777  				  Monochrome Video Memory
; 0x000B8000 - 0x000BFFFF  				  Color Video Memory
; 0x000C0000 - 0x000C7FFF  				  Video ROM BIOS
; 0x000C8000 - 0x000EFFFF  				  BIOS Shadow Area
; 0x000F0000 - 0x000FFFFF  				  System BIOS
;
; By default, and traditionaly, BIOS loads the Bootloader in the free
; 512 bytes block  (*) from table. And its maximum lenght are those 512 bytes.
; We are gonna need more memory, so a Two Stages bootloader is required.
; The first Stage will be placed in that Second Free Block (*), and will
; load the real bootloader, allocated in the following Block (**), wich allows
; us to extend its code up to 480 KiB.
; The last block (***) represented in the table, is gonna be used
; for allocating the STACK.



;-------------------------------------------------------------------------------
;
; 	BOOTLOADER : STAGE 1
;
;-------------------------------------------------------------------------------

STACK_TOP 		EQU 	0x8000
STACK_BASE 		EQU 	0x0000

main:
	; reset registers
	xor 	ax, 	ax
	xor 	bx, 	bx
	xor 	cx, 	cx
	xor 	dx, 	dx

	cli         					; Disable interrupts to set SS and SP atomically
									; ( ¿only required for <= 286? )

	; Data Segment
	mov 	ax, 	0x00
	mov 	ds, 	ax 				; set data segment to 0x00

	; Stack Segment
	add 	ax, 	STACK_TOP
	mov 	ss, 	ax 				; Stack Segment will have the top at ( 0x8000:0x00 )

	; Stack Pointer Offset
	mov 	sp, 	STACK_BASE  	; Bottom of stack

	; Other Segments
	mov 	ax, 	0xB800 			; (0x0B80:0x00) Video buffer
	mov 	gs, 	ax     			; Copy address of video buffer to extra segment

 	sti 							; Enable Interrupts again


	mov 	ah, 	0				; Set new video mode
	mov 	al, 	10h				; Video mode = 10h (80x25 with 16 colors)

	mov 	byte [gs:0], 	'L'
	mov 	byte [gs:2], 	'o'
	mov 	byte [gs:4], 	'a'
	mov 	byte [gs:6], 	'd'
	mov 	byte [gs:8], 	'i'
	mov 	byte [gs:10],	'n'
	mov 	byte [gs:12], 	'g'
	mov 	byte [gs:14], 	'.'
	mov 	byte [gs:16], 	'.'
	mov 	byte [gs:18], 	'.'


	mov 	ax, 	0x07E0
	mov 	es, 	ax 			; declare sector where will code be loaded
	mov  	al, 	1 		    ; Load 1 sector
	mov  	bx, 	0x0000  	; Destination address.
	mov  	ch, 	0       	; Cylinder 0,
	mov  	cl, 	2 		    ; Sector 2
	mov  	dl, 	0     	 	; Drive 0
	mov  	dh, 	0 	        ; Head 0
	call 	readSectors
	jnc  	.success           	; if carry flag is set, either the disk system
								; wouldn't reset, or we exceeded our maximum
								; attempts and the disk is probably damaged
	mov 	byte [gs:20], 	'E'
	mov 	byte [gs:22], 	'R'
	mov 	byte [gs:24], 	'R'
	mov 	byte [gs:26], 	'O'
	mov 	byte [gs:28], 	'R'
	call 	.halt

	.success:
		jmp 	0x0000:0x7E00
	    call 	.halt

	.halt:
	    cli
	    hlt
	    jmp .halt


;;******************************************************************************
 ;
 ;  readSectors()
 ;	Reads sectors from disk using BIOS services and stores them in requested
 ; 	memory adress
 ;
 ;  Input 		AL = Number of sectors to read (must be nonzero)
 ;      		BX = Destination adress (ES:BX , data buffer)
 ; 				CH = Low eight bits of cylinder number
 ;      		CL = [7:6] xx------ Hight 2 bits of cylinder num. Hard disk only
 ; 					 [5:0] --xxxxxx Sector number (1-63)
 ;					 ( When setted, CL[7:6]+CH will be used as cylinder number )
 ;      		DL = Drive number (bit 7, set for hard disk)
 ;      		DH = Head number
 ;
 ; 	Output  	CF = 0 (suces) | 1 (failure)
 ;
 ; 	Destroy 	AX
 ;
 ;******************************************************************************
readSectors:
    mov 	si, 	3			; Maximum attempts - 1
	.read:
	    mov 	ah,		0x02 	; read sectors into memory (int 0x13, ah = 0x02)
	    int 	0x13 			; call interrupt
	    jnc 	.done       	; If read succeeded Finish
	    dec 	si          	; ...if not, decrement attempts counter
	    jc  	.done       	; If maximum attempts exceeded (CF=1) Exit
	    xor 	ah, 	ah 	   	; ...else, reset disk system (int 0x13, ah=0x00)
	    int 	0x13 			; call interrupt
	    jnc 	.read       	; If reset succeeded, Retry ( otherwise Finish )
	.done:
		; TO DO: Status code return
		; AH should contain status of previous operation
		; ...but some BIOS return it in AL.
		; Satus Codes Table ref: http://www.ctyme.com/intr/rb-0606.htm#Table234
		xor 	ax, 	ax
		RET


; Magic bytes.
times ((512 - 2) - ($ - $$)) db 0x00
dw 0xAA55


