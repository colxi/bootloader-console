use16 				;force 16 bits binary

GDT:
	gdt_start:
		gdt_null:
		    dd 		0x0				; null descriptor
		    dd 		0x0 			; null descriptor

		gdt_code:
		    dw 		0xffff 			; limit low. segment length 0-15
		    dw 		0x0 			; base low
		    db 		0x0 			; base middle
		    db 		10011010b		; access permisions
		    db 		11001111b 		; granularity
		    db 		0x0 			; base high

		gdt_data:
		    dw 		0xffff
		    dw 		0x0
		    db 		0x0
		    db 		10010010b
		    db 		11001111b
		    db 		0x0
	gdt_end:

	gdt_descriptor:
	    dw 		gdt_end - gdt_start - 1
	    dd 		gdt_start

NULL_SEG equ gdt_null
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
