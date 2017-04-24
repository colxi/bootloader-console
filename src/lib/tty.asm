use16
TTY_BUFFER_SIZE     EQU 512                     ; Max sie of the tty input
tty_buffer:         times TTY_BUFFER_SIZE db 0  ; Buffer to store keystrokes
tty_buffer_extra    db 0                        ; Ensures NULL ending when input
                                                ; length = TTY_BUFFER_SIZE. This
                                                ; prevents buffer overflow.
s_unknown_command   db "Unknown command : ", 0
s_help_command      db "Available commands : help | clear | ...", 10, 0

tty_commands:
    .help           db "help", 0
    .clear          db "clear", 0


initTTY:
    .prompt:
        mov     al,     ">"
        call    printChar
        mov     cx,     0               ; reset buffer position
    .getKey:
        mov     ah,     0x00            ; bios read keystroke (waits till stroke)
        int     16h                     ; bios keyboard services.

        mov     bx,     tty_buffer      ; get buffer pointer
        add     bx,     cx              ; add the length of buffered string

        cmp     al,     8               ; if pressed key is BACKSPACE...
        je      .printBackspace         ;

        cmp     al,     13              ; if pressed key is ENTER...
        je      .printEnter             ; proccess typed string instruction

        cmp     al, 32                  ; if is not a printable character...
        jb     .getKey                  ; discard keystroke
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        cmp     cx , TTY_BUFFER_SIZE
        jb     .addChar                 ; if still space in buffer add char

        jmp     .getKey                 ; listen to next keystoke

    ;***************************************************************************
    .addChar:
        mov     [bx],   byte al         ; insert typed character at end position
        inc     cx                      ; increase string lenght counter
        call    printChar               ; print the prssed character
        jmp     .getKey                 ; listen to next keystoke
    ;***************************************************************************
    .printBackspace:
        cmp     cx,     0               ; if in beggining of buffer
        je      .getKey                 ; ignore keystroke

        call    getCursor               ; check current cursor position
        cmp     dl,     1               ; che k if cursor is in FIRST column
        jnb     .cleanCharacter         ; if NOT... jump to .cleanCharacter
        dec     dh                      ; if FIRST column, move cursor a ROW up
        mov     dl, VIDEO_COLS          ; and to last COLUMN
        call    setCursor

        .cleanCharacter:
        mov     al,     8               ; garantee BACKSPACE char to AL
        call    printChar               ; print char 8 (backspace cursor back)

        mov     [bx],   byte 0          ; clear last byte in buffered string
        dec     cx                      ; decrement by 1 the sting length
        jmp     .getKey                 ; listen to next keystoke
    ;***************************************************************************
    .printEnter:
        mov     [bx],   byte 0          ; insert null char at the end of string
        mov     ax,     tty_buffer
        call    printLF                 ; print line break
        call    interpreterTTY          ; call interpreter
        jmp     .prompt                 ; restart prompt
        RET



interpreterTTY:
    pusha

    mov     ax,     tty_buffer
    call    trim                        ; trim the inserted command
    mov     bx,     ax

    ; -----------------------------------------------------------  test (empty)
    mov     ax,     EMPTY_STRING
    call    strcmp
    cmp     cx,     0x01
    je      .done
    ; -----------------------------------------------------------  test 'help'
    mov     ax,     tty_commands.help
    call    strcmp
    cmp     cx,     0x01
    je      ._ttyHelp
    ; -----------------------------------------------------------  test 'clear'
    mov     ax,     tty_commands.clear
    call    strcmp
    cmp     cx,     0x01
    je      ._ttyClear
    ; -----------------------------------------------------------  (...)
    ;
    ; (...)
    ;
    ; -----------------------------------------------------------UNKNOWN COMMAND
    mov     ax,     s_unknown_command
    call    print                       ; print error string
    mov     ax,     tty_buffer          ; move to AX the buffer begining pointer
    call    print                       ; print user input
    call    printLF                     ; jump to new line
    jmp     .done
    ._ttyHelp:
        call    ttyHelp
        jmp     .done
    ._ttyClear:
        call    ttyClear
        jmp     .done
    .done:
        popa
        RET

ttyHelp:
    mov ax , s_help_command
    call print
    RET


ttyClear:
    call clearScreen
    RET

