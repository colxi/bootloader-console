use16
TTY_BUFFER_SIZE     EQU 512                     ; Max sie of the tty input
tty_buffer:         times TTY_BUFFER_SIZE db 0  ; Buffer to store keystrokes
tty_buffer_ending   db 0                        ; Ensures NULL ending when input
                                                ; length = TTY_BUFFER_SIZE. This
                                                ; prevents buffer overflow.
tty_params_address: dw 0                        ; Store the address of the begin
                                                ; of the arguments in tty cmmand
s_unknown_command   db "Unknown command : ", 0

include 'tty/command-def.asm'

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
        call    printLF                 ; print line break
        call    interpreterTTY          ; call interpreter
        jmp     .prompt                 ; restart prompt


interpreterTTY:
    pusha
    push si

    mov     ax,     tty_buffer      ; prepare to trim
    call    trim                    ; trim the inserted command

    ;
    ; SEARCH ARGUMENTS IN STRING
    ;
    mov     bl,     " "             ; pepare to search arguments in command
    call    strchr                  ; search space character in tty_buffer
    cmp     cx,  0x0000             ; if no arguments found...
    je      .processCommand         ; proccess command
    ; Args found!
    mov     si, cx                  ; Split string, inserting NULL char...
    mov     [si], byte  0x00        ; ...in the position on the SPACE char
    inc     cx                      ; move pointer after the NULL char inserter
    mov     [tty_params_address], cx; and set pointer to arguments variable
    ;
    ; PROCESS COMMAND
    ;
    .processCommand:
        mov     bx,     tty_buffer  ; set second operand for strcmp
        ; -----------------------------------------------------------  test (empty)
        mov     ax,     EMPTY_STRING
        call    strcmp
        cmp     cx,     0x01
        je      .done
        ; -----------------------------------------------------------
        include 'tty/command-identify.asm'
        ; -----------------------------------------------------------UNKNOWN COMMAND
        mov     ax,     s_unknown_command
        call    print                       ; print error string
        mov     ax,     tty_buffer          ; move to AX the buffer begining pointer
        call    print                       ; print user input
        call    printLF                     ; jump to new line
        .done:
            pop si
            popa
            RET
