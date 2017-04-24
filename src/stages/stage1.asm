org 0x7C00  		;Boot loader start address
use16 				;force 16 bits binary

;-------------------------------------------------------------------------------
;
; 	BOOTLOADER : STAGE 1
;
;-------------------------------------------------------------------------------

; jump to entry point
jmp main

; Use FASM preprocessing to calculate Sector2 Size
; and calculate thr number of disk sectors to be loaded.
STAGE2_SIZE 		   EQU  (___stage2_end_offset - ___stage2_start_offset)
STAGE2_SECTORS_COUNT   EQU  ( ( STAGE2_SIZE - ( STAGE2_SIZE mod 512) ) / 512 )+1
STAGE2_SEGMENT		   EQU  0x0000
STAGE2_OFFSET		   EQU  0x7E00

VIDEO_MODE 			   EQU 	0x03 	; text mode
VIDEO_COLORS 		   EQU  0x17 	; grey over blue background
VIDEO_COLS 	 		   EQU  80
VIDEO_ROWS 	 		   EQU  25

EMPTY_STRING  	 db 	'', 0

s_preparing      db    '[Bootloader]',  10, 0
s_stage1Loaded 	 db    'Stage 1 loaded at 0x0000:0x7C00 (512 bytes)' , 10, 0
s_ReadingDisk	 db    'Read Stage 2 from Disk (sector 2)' , 10, 0
s_stage2Loaded_1 db    'Stage 2 Loaded at 0x0000:0x7E00 (' , 0
s_stage2Loaded_2 db    ' bytes + sector padding)' , 10, 0
s_FlDiskReadErr  db    'Disk Read ERR' , 10, 0
s_bootl_ready    db    'Ready!', 10, 10, 0


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
	mov ax, VIDEO_MODE
	int 	0x10

	call 	clearScreen

	; reset disk drive , go to the first Sector on disk.
	mov 	ah,		0x00
	mov 	dl,		0
	int 	0x13


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
	mov ax, s_preparing
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
	jmp 	.halt 					; halt system
	;---------------------------------------------------------------------------
	.success:
		;--- info output block
	    mov     ax,     s_stage2Loaded_1
	    call    print
	    mov 	ax, 	STAGE2_SIZE
	    call 	uitoa
	    mov 	ax, 	cx
	    call 	print
	    mov 	ax, 	s_stage2Loaded_2
	    call 	print

		jmp 	STAGE2_SEGMENT:STAGE2_OFFSET 	; READY! jump to stage2 2
	;---------------------------------------------------------------------------
	.halt:
		hlt
		jmp .halt

;**************************************************
;
; ESSENTIAL I/O PROCEDURES
;
;**************************************************

;;******************************************************************************
 ;
 ;   uitoa()  - Returns the ASCII Decimal representation of
 ;              UNSIGNED values stored in AX (16 bits).
 ;              Note: Algorithm moves in decending order,
 ;              from las digit, to first digit.
 ;   + input :
 ;       AX = Unsigned integer to convert
 ;   + output :
 ;       CX = Pointer to string in memory
 ;
 ;**************************************************
uitoa:
    push ax
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
        mov     cx,     si          ; store buffer pointer in ax

        pop dx
        pop bx
        pop ax
        RET
    .buffer: times 7 db 0         	; 16bit integer max length=5
                                    ; + extra byte is added to fit thr negative
                                    ; 	symbol (-) when processing calls from
                                    ; 	ITOA proc and handñing negative numbers
                                    ; + null

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

;;******************************************************************************
 ; Routine: output string in AX to screen
 ;**************************************************
print:
    pushf

    cld 								; CLear Direction flag. Direction:ASC
    mov     si,     ax                  ; copy input address to Source Index
    .nextChar:
        lodsb                           ; load string byte: retrieves a byte of data from the location pointed
                                        ; to by SI, and stores it in AL (the lower byte of AX)
        cmp     al,     0
        je      .done                   ; If char is zero, end of string detected!
        call    printChar               ; Otherwise, print it
        jmp     .nextChar               ; and go with next char
    .done:
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

    cmp 	al,		10 			; if ENTER character, jump to new Line
    je  	.char_LF

    mov 	ah, 	0x0E    	; 0x0E = single character BIOS print service
    mov 	bh, 	0x00    	; Page no. 0
    mov 	bl, 	VIDEO_COLORS; Text attribute colors
    int 	0x10        		; Call BIOS video interrupt

	cmp 	al,		8 			; if BACKSPACE called, remove characgter
    je  	.char_backspace

    jmp 	.done
    ;---------------------------------------------------------------------------
    .char_backspace:
	    mov 	ah, 	0x09    	; 0x0E = print without moving cursor
	 	mov 	al, 	0x00     	; NULL character
	    mov 	bh, 	0x00    	; Page no. 0
	    mov 	bl, 	VIDEO_COLORS; Text attribute 0x07 is lightgrey font on black background
	    mov 	cx, 	0x01    	; print 1 time the character
	    int 	0x10        		; Call BIOS video interrupt
        jmp     .done
    ;---------------------------------------------------------------------------
    .char_LF:
        call 	printLF
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
    push ax 		; prevent int10h destroy register
    push bx 		; prevent procedure destroy register
    push cx 		; prevent int10h destroy register

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
    mov ah, 0x06 			 ; Clear/Scroll Screen Up
    mov al, 00  			 ; Number of lines to scroll (0=clear entire window)
    mov bh, VIDEO_COLORS     ; Colors
    mov cx, 0x0000     		 ; Row&Col numbers of upper left corner
    mov dh, VIDEO_ROWS-1     ; Lower Row number
    mov dl, VIDEO_COLS-1     ; Most Right Col number
    int 0x10       			 ; BIOS Video Services

    mov dx , 0x0000 		 ; mov vursor to up left on screen
    call setCursor

    popa
    RET

; pad with zeroes sector one -2 (magic bytes lenght)
times ((512 - 2) - ($ - $$)) db 0x00
; Magic bytes.
dw 0xAA55


