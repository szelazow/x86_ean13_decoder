section .rodata
        codes_L db 01110010b, 01100110b, 01101100b, 01000010b, 01011100b, 01001110b, 01010000b, 01000100b, 01001000b, 01110100b
        codes_G db 01011000b, 01001100b, 01100100b, 01011110b, 01100010b, 01000110b, 01111010b, 01101110b, 01110110b, 01101000b
        codes_R db 00001101b, 00011001b, 00010011b, 00111101b, 00100011b, 00110001b, 00101111b, 00111011b, 00110111b, 00001011b
        codes_first db 00000000b, 00001011b, 00001101b, 00001110b, 00010011b, 00011001b, 00011100b, 00010101b, 00010110b, 00011010b

section .text
global decode_ean13

;       al -  counter used to check how many bits are left in the currently read byte
;       ah -  current byte
;       bh -
;       bl - 
;       cl - 
;       ch -  
;       dh -  
;       dl - 
;       esi - output buffer
;       edi - image

decode_ean13:
        ; prologue
        push    ebp
        mov     ebp, esp
        sub     esp, 4
        push    ebx
        push    esi
        push    edi
        mov     esi, [ebp + 8]         ; out
        mov     edi, [ebp + 12]        ; img

        xor     cl, cl

load_byte:
        mov     al, 8                  ;counter checking the amount of bits left in current byte
        mov     ah, BYTE[edi]          ;current byte
        inc     edi

check_modsize:
        inc     cl                     ;used to calculate the width of 1 module
        dec     al
        jz      load_byte
        shl     ah, 1
        jns     check_modsize
        mov     [ebp-4], cl

skip_01:                              ;skip the second and third bars
        call    read_bar
        call    read_bar              ;every ean-13 code starts with a sequence of black - white - black: we read the first black bar to set modsize, so we'll have to skip 2 more bars.

;       bl - number counter
;       bh - bar counter
;       cl - currently read
;       ch - used in reading
;       edx - countdown from 9 to 0
first_six:
        mov     bl, 6
        inc     esi                  ;skip first character for now
        
left_number_loop:
        xor     cl, cl
        mov     bh, 7

left_bar_loop:
        call    read_bar
        dec     bh
        jnz     left_bar_loop

read_left:
        mov     edx, 10

left_read_loop:
        dec     edx
        mov     ch, [codes_L + edx]
        cmp     ch, cl
        je      found_L
        mov     ch, [codes_G + edx]
        cmp     ch, cl
        jne     left_read_loop

found_G:
        shl     ch, 1
        inc     ch              ;if L sequence append 0, if G sequence append 1
        jmp     left_read_finish

found_L:
        shl     ch, 1

left_read_finish:
        mov     [esi], edx
        inc     esi
        dec     bl
        jnz     left_number_loop
        jmp     epilogue

;       al  - counter checking if byte was fully passed through
;       ah  - current byte
;       ebx - number counters used by reading loops
;       cl  -  output[read value]
;       ch  -  mod width counter
;       edx - 

read_bar:
        mov     ch, BYTE[ebp-4]               ;store the amount of bits per module into a counter
        test    al, al                        ;check if byte was fully passed through
        jz      get_byte

skip_loop:
        dec     ch      
        jz      get_module_value
        shl     ah, 1
        dec     al
        jnz     skip_loop

get_byte:
        mov     al, 8
        mov     ah, BYTE[edi]   
        inc     edi
        test    ch, ch
        jnz     skip_loop               ;do not start skipping if module width is 1

get_module_value:
        dec     al
        shl     cl, 1
        shl     ah, 1
        jnc     read_finished
        inc     cl                  ;if not zero set current read to 1

read_finished:
        ret

epilogue:
        ; epilogue
        pop     edi
        pop     esi
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret







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
        cmp     bl, ch
        jne     first_loop

first_read_finish:
        mov     [esi], dh
        jmp     epilogue
