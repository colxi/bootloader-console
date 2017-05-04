; -----------------------------------------------------------  test 'help'
mov     ax,     tty_commands.help
call    strcmp
cmp     cx,     0x01
je      ttyHelp
; -----------------------------------------------------------  test 'clear'
mov     ax,     tty_commands.clear
call    strcmp
cmp     cx,     0x01
je      ttyClear
; -----------------------------------------------------------  test 'boot'
mov     ax,     tty_commands.boot
call    strcmp
cmp     cx,     0x01
je      ttyBoot
; -----------------------------------------------------------  (...)

; (...)
