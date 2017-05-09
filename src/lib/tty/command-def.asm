; Add the command name i the available commands list
tty_commands:
    .help           db "help", 0
    .clear          db "clear", 0
    .boot           db "boot", 0
    .bootsec        db "bootsec", 0

; Add command name in the HELP list
s_help_command      db "Available commands : help | clear | boot | bootsec", 10, 0

;
; PROCEDURE INCLUDES
;
include 'command/ttyHelp.asm'
include 'command/ttyClear.asm'
include 'command/ttyBoot.asm'
include 'command/ttyBootSec.asm'
