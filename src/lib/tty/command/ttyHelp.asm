ttyHelp:
    mov     ax , s_help_command
    call    print
    jmp     interpreterTTY.done
