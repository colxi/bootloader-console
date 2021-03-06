;-------------------------------------------------------------------------------
;
;  Name           : string-manipulation.asm
;
;  Description    : 16BIT FASM assembly minimal library focused into provide
;                   the essential resources, to string manipulation
;
;                   Contents:
;                   strcmp | strlen | strchr | trim | ltrim | rtrim
;                   To do:
;                   toupper | tolower | strtoupper | strtolower
;
;  Version        : 1.1
;  Created        : 27/03/2017
;  Author         : colxi
;
;-------------------------------------------------------------------------------



;;******************************************************************************
 ;  strcmp() -  Compares string pointed by AX with string pointed by BX, and
 ;              returns Boolean result in CX.  Both string must be ENDED ended
 ;  Input:
 ;      AX - pointer to String 1
 ;      BX - pointer to string 2
 ;  Ouptut:
 ;      CX - 0x01 (equal) | 0x00 (not equal)
 ;  Modifies:
 ;      -none-
 ;
 ;******************************************************************************
strcmp:
    pushf
    push    si
    push    di
    push    ax

    cld                                 ; CLear Direction flag. Direction:ASC
    mov     si,     ax                  ; ds:SI points to first string
    mov     di,     bx                  ; ds:DI points to second string

    mov     ah,     0x01                ; init with TRUE ,the comparation result
    dec     di                          ; decrement ds:di pointer
    .nextChar:
        inc     di                      ; next character in string 2
        lodsb                           ; load into AL next char from string 1
                                        ; ( lodsb will autoincrement SI )
        cmp     [di],   al              ; Compare characters
        jne     .notEqual               ; break loop if different

        cmp     al,     0x00            ; ¿ end of string ?
        jne     .nextChar               ; no... get next char
        jmp     .done                   ; yes... done!
    .notEqual:
        mov     ah,     0x00            ; set FALSE comparation result
        ;-----------------------------------------------------------------------
    .done:
        xor     cx,     cx              ; prepare CX to receive  result
        mov     cl,     ah              ; store in CL the result

        pop     ax
        pop     di
        pop     si
        popf
        RET




;;******************************************************************************
 ;  strlen() -  Returns the positive decimal value representing the number of
 ;              characters in a NULL terminated string.
 ;  Input:
 ;      AX - pointer to String
 ;  Ouptut:
 ;      CX - count of characters
 ;  Modifies:
 ;      -none-
 ;
 ;******************************************************************************
strlen:
    pushf
    push    si
    push    ax                          ; save AX original value

    cld                                 ; CLear Direction flag. Direction:ASC
    mov     si,     ax                  ; copy input address to Source Index
    xor     cx,     cx                  ; init counter to 0
    .nextChar:
        lodsb                           ; get next byte in AL
        cmp     al,     0               ; it's ZERO ?
        jz     .done                    ; IT IS! done...
        inc    cx                       ; IT'S NOT.... increment counter
        jmp    .nextChar                ; check net char...
        ;-----------------------------------------------------------------------
    .done:
        pop     ax
        pop     si
        popf
        RET



;;******************************************************************************
 ;  strchr() -  Searchs first match of the provided CHAR in the requested STRING
 ;              and returns a pointer to it or NULL (0x0000) if no match.
 ;  Input:
 ;      AX - pointer to String
 ;      BL - character to find
 ;  Ouptut:
 ;      CX - Pointer to position (or NULL if no match)
 ;  Modifies:
 ;      -none-
 ;
 ;******************************************************************************
strchr:
    pushf
    push    ax
    push    si

    cld                                 ; CLear Direction flag. Direction:ASC
    mov     si,     ax                  ; ds:SI points to string

    mov     cx,     0x0000              ; init with FALSE ,the search result
    .nextChar:
        lodsb                           ; load into AL next char from string
                                        ; ( lodsb will autoincrement SI )
        cmp     al,     bl              ; Compare characters
        je      .found                  ; break loop if found

        cmp     [si],   byte 0x00       ;  ¿ end of string ?
        jne     .nextChar               ; no... get next char
        jmp     .done                   ; yes... done!
    .found:
        dec     si
        mov     cx,     si              ; set the pointer of the match
        ;-----------------------------------------------------------------------
    .done:
        pop     si
        pop     ax
        popf
        RET


;;******************************************************************************
 ;  trim() -  Trims left and right the provided null terminated string.
 ;            NOTE: MODIFIES ORIGINAL STRING
 ;            Removes : SPACEBAR chars          (" ")
 ;                      TABS chars              (\t)
 ;                      New Line chars          (\r)
 ;                      Carraige return char    (\n)
 ;                      Vertical TAB char       (\x0B)
 ;
 ;  Input:
 ;      AX - pointer to String
 ;  Ouptut:
 ;      AX - pointer to (timmed) string
 ;  Modifies:
 ;      -none-
 ;
 ;******************************************************************************
trim:
    call ltrim
    call rtrim
    RET



;;******************************************************************************
 ;  ltrim() - Trims left the provided null terminated string.
 ;            NOTE: MODIFIES ORIGINAL STRING
 ;            Removes : SPACEBAR chars          (" ")
 ;                      TABS chars              (\t)
 ;                      New Line chars          (\r)
 ;                      Carraige return char    (\n)
 ;                      Vertical TAB char       (\x0B)
 ;
 ;  Input:
 ;      AX - pointer to String
 ;  Ouptut:
 ;      AX - pointer to (timmed) string
 ;  Modifies:
 ;      -none-
 ;
 ;******************************************************************************
ltrim:
    pushf                               ; push FLAG register
    push   si
    push   di
    push   ax
    push   cx

    cld                                 ; CLear Direction flag. Direction:ASC

    mov    si,     ax                   ; ds:SI points to first char
    mov    di,     ax                   ; ds:DI points to first char
    .nextChar:
        lodsb                           ; load in AL char from SI (and inc SI+1)
        cmp     al,     32              ; check : SPACEBAR char (" ")
        je      .nextChar               ; IT IS! ...next character
        cmp     al,     9               ; check : TAB char (\t)
        je      .nextChar               ; IT IS! ...next character
        cmp     al,     10              ; check : New line char (\r)
        je      .nextChar               ; IT IS! ...next character
        cmp     al,     13              ; check : Carriage return char (\n)
        je      .nextChar               ; IT IS! ...next character
        cmp     al,     11              ; check : Vertical TAB char (\x0B)
        je      .nextChar               ; IT IS! ...check next character
        ;-----------------------------------------------------------------------
    dec     si                          ; decrement SI pointer by 1, to undo
                                        ; the last pointer position increment

    mov     ax,     si
    call    strlen                      ; get string length from current position
                                        ; (after trimmed chars)
    inc     cx                          ; add extra byte length (end NULL char)
    rep     movsb                       ; REPEAT mov single bit, from SI to DI
                                        ; until the counter CX=0 (set by strlen)

    pop     cx
    pop     ax                          ; Recover pointer to begining of string
    pop     di
    pop     si
    popf                                ; recover FLAGS
    RET



;;******************************************************************************
 ;  rtrim() -  Trims right the provided null terminated string.
 ;            NOTE: MODIFIES ORIGINAL STRING
 ;            Removes : SPACEBAR chars          (" ")
 ;                      TABS chars              (\t)
 ;                      New Line chars          (\r)
 ;                      Carraige return char    (\n)
 ;                      Vertical TAB char       (\x0B)
 ;
 ;  Input:
 ;      AX - pointer to String
 ;  Ouptut:
 ;      AX - pointer to (timmed) string
 ;  Modifies:
 ;      -none-
 ;
 ;******************************************************************************
rtrim:
    pushf                               ; push FLAG register
    push    si
    push    ax
    push    cx

    call    strlen                      ; calculate length of string
    add     ax , cx                     ; put string pointer to last character
    dec     ax                          ; move back pointer before NULL end char

    mov    si,     ax                   ; Assign address to ds:SI
    std                                 ; CLear Direction flag. Direction:DESC

    .prevChar:
        lodsb                           ; load in AL char from SI (and sub SI-1)
        cmp     al,     32              ; check : SPACEBAR char (" ")
        je      .prevChar               ; IT IS! ...next character
        cmp     al,     9               ; check : TAB char (\t)
        je      .prevChar               ; IT IS! ...next character
        cmp     al,     10              ; check : New line char (\r)
        je      .prevChar               ; IT IS! ...next character
        cmp     al,     13              ; check : Carriage return char (\n)
        je      .prevChar               ; IT IS! ...next character
        cmp     al,     11              ; check : Vertical TAB char (\x0B)
        je      .prevChar               ; IT IS! ...check next character
        ;-----------------------------------------------------------------------
    inc     si                          ; increment SI pointer by 1, to undo
                                        ; the last pointer position decrement
    mov [si+1], byte 0                  ; add NULL termination after last char

    pop     cx
    pop     ax                          ; Recover pointer to begining of string
    pop     si
    popf                                ; recover FLAGS
    RET



;;******************************************************************************
 ;  isPrintable() : Analyze character in AL, and determine if is a printable
 ;                  char.
 ;  Input:
 ;      AL : Character to analyze
 ;  Output:
 ;      CL : 0x01 for true and 0x00 for false
 ;  Modifies:
 ;      (none)
 ;
 ;******************************************************************************
isPrintable:
    mov     cl ,    0x01    ; by default is printable
    cmp     al ,    0x1F    ; check AL value agains 0x21
    ja      .done           ; if is GREATER is printable, done!
    mov     cl ,    0x00    ; if is lower, is not printable
    .done:
        RET


;;******************************************************************************
 ;
 ;
 ; mask AL with AH if character in AL is not printable
 ;******************************************************************************
maskNotPrintable:
    push cx
    call    isPrintable
    cmp     cl,     0x01
    je      .done
    mov     al ,    ah
    .done:
        pop cx
        RET


;toupper
;tolower
;strtoupper
;strtolower
;isalpha
;isdigit
;isalnum
