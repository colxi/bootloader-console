;----------------------------------------------------------------------------
;
;  FASM x86 Bootloader Verbose
;  Version        :    	1.0
;  Created        :		24/03/2017
;  Author         :    	colxi
;  Description    :
;
;---------------------------------------------------------------------------

format binary as 'img'  ;set executable as flat binary compiled to .img file
use16 					;force 16 bits binary


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

; BIOS will automatically load in 0x7C00 stage1 (512 bytes)
include 'stages/stage1.asm'
; following code needs to be loaded manually ti mem, in stage 1 execution
include 'stages/stage2.asm'






