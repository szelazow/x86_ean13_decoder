section .rodata
        codes_L db 01110010b, 01100110b, 01101100b, 01000010b, 01011100b, 01001110b, 01010000b, 01000100b, 01001000b, 01110100b
        codes_G db 01011000b, 01001100b, 01100100b, 01011110b, 01100010b, 01000110b, 01111010b, 01101110b, 01110110b, 01101000b
        codes_R db 00001101b, 00011001b, 00010011b, 00111101b, 00100011b, 00110001b, 00101111b, 00111011b, 00110111b, 00001011b
        codes_first db 00000000b, 00001011b, 00001101b, 00001110b, 00010011b, 00011001b, 00011100b, 00010101b, 00010110b, 00011010b

section .text
global decode_ean13

;       ah -  current byte counter - eax is used for byte logic 
;       al -  to be skipped per iteration
;       ebx - 
;       cl -  current byte
;       ch - 
;       dh -  used for reading the first digit
;       dl - 
;       esi - output buffer
;       edi - image
;       

decode_ean13:
        ; prologue
        push    ebp
        mov     ebp, esp
        push    ebx
        push    esi
        push    edi

        mov     esi, [ebp + 8]         ; out
        mov     edi, [ebp + 12]        ; img

        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx

load_byte:
        mov     ah, 8
        mov     cl, BYTE[edi]
        inc     edi

check_modsize:
        inc     al
        dec     ah
        jz      load_byte
        shl     cl, 1
        jns     check_modsize
        dec     al                    ;amount to be skipped - module size - 1
;       bl - skip counter
skip_01:                              ;skip the second and third bars
        call    read_bar
        call    read_bar

;       bl - number counter
;       bh - bar counter
;       ch - currently read
first_six:
        mov     bl, 6
        inc     esi                  ;skip first character for now
        
left_number_loop:
        xor     ch, ch
        dec     bl
        mov     bh, 7

left_bar_loop:
        call    read_bar
        dec     bh
        test    bh, bh
        jnz     left_bar_loop

;       dh - stores AB sequence, used for setting the first digit of the code
read_left:
        push    ebx
        push    edi
        mov     edi, 10

left_read_loop:
        dec     edi
        lea     ebx, [codes_L + edi]
        mov     bl, [ebx]
        cmp     bl, ch
        je      found_L
        lea     ebx, [codes_G + edi]
        mov     bl, [ebx]
        cmp     bl, ch
        jne     left_read_loop

found_G:
        shl     dh, 1
        inc     dh              ;if L sequence append 0, if G sequence append 1
        jmp     left_read_finish

found_L:
        shl     dh, 1

left_read_finish:
        mov     [esi], edi
        inc     esi
        pop     edi
        pop     ebx
        test    bl, bl
        jnz     left_number_loop


skip_middle:
        mov     bl, 5

skip_middle_loop:
        call    read_bar
        dec     bl
        jnz     skip_middle_loop

last_six:
        mov     bl, 6

right_number_loop:
        xor     ch, ch
        dec     bl
        mov     bh, 7

right_bar_loop:
        call    read_bar
        dec     bh
        jnz     right_bar_loop

read_right:
        push    ebx
        push    edi
        xor     dl, dl
        mov     edi, 10

right_read_loop:
        dec     edi
        lea     ebx, [codes_R + edi]
        mov     bl, [ebx]
        cmp     bl, ch
        jne     right_read_loop

right_read_finish:
        mov     [esi], edi
        inc     esi
        pop     edi
        pop     ebx
        test    bl, bl
        jnz     right_number_loop

first:
        sub     esi, 13
        xor     ch, ch
        mov     bh, 7

first_bar_loop:
        call    read_bar
        dec     bh
        jnz     first_bar_loop

bar_read:
        mov     eax, 10

first_loop:
        dec     eax
        lea     ebx, [codes_first + eax]
        mov     bl, [ebx]
        cmp     bl, dh
        jne     first_loop

first_read_finish:
        mov     [esi], al
        jmp     epilogue


;       ch - buffer of currently collected values
;       dl - module width counter
;       cl -  current byte
read_bar:
        mov     dl, al               ;store the amount of bits per module into a counter
        test    ah, ah               ;check if byte was fully passed through
        jnz     check_if_skip

get_byte:
        mov     ah, 8
        mov     cl, BYTE[edi]   
        inc     edi

check_if_skip:
        test    dl, dl
        jz      get_module_value

skip_loop:
        shl     cl, 1
        dec     dl
        dec     ah
        jz      get_byte
        test    dl, dl
        jnz     skip_loop

get_module_value:
        dec     ah
        shl     ch, 1
        shl     cl, 1
        jnc     read_finished
        inc     ch                  ;if not zero set current read to 1

read_finished:
        ret

epilogue:
        ; epilogue
        pop edi
        pop esi
        pop ebx
        pop ebp
        ret
