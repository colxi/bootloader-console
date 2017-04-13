format binary as 'img'  ;set executable as flat binary compiled to .img file
use16 					;force 16 bits binary

include 'stages/stage1.asm'
include 'stages/stage2.asm'
include 'lib/standard-io.asm'

; Pad image to multiple size of 512 bytes.
times ((512 * 64) - ($ - $$)) db 0x00




