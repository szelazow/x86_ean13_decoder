section .data
        codes_L: db 00001101b, 00011001b, 00010011b, 00111101b, 00100011b, 00110001b, 00101111b, 00111011b, 00110111b, 00001011b
        codes_G: db 00100111b, 00110011b, 00011011b, 00100001b, 00011101b, 00111001b, 00000101b, 00010001b, 00001001b, 00010111b
        codes_R: db 01110010b, 01100110b, 01101100b, 01000010b, 01011100b, 01001110b, 01010000b, 01000100b, 01001000b, 01110100b

section .text
global decode_ean13

;       ah -  current byte counter
;       al -  bits per module
;       bh
;       bl -  
;       ebx - used for counters
;       cl -  current byte
;       ch -  
;       dh -  bits per module
;       dl 
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
        xor     edx, edx
        xor     ecx, ecx

load_byte:
        mov     ah, 8
        mov     cl, BYTE[edi]
        inc     edi

check_modsize:
        inc     dh
        dec     ah
        test    ah, ah
        jz      load_byte
        shl     cl, 1
        jc      check_modsize

;       bl - skip counter
        mov     bl, 2
skip_01:                              ;skip the second and third bars
        call    read_bar
        dec     bl
        test    bl, bl
        jnz     skip_01

        mov     bl, 6
        inc     esi                  ;skip first character for now
first_six:
        test    bl, bl
        jz      first_finished
        call    read_number
        dec     bl
read_number_A:
        



first_finished:
        mov     bl, 5                  ;set up for skipping through the 5 middle bits
skip_middle:
        call    read_bar
        dec     bl
        test    bl, bl
        jnz     skip_middle

second_six:

first_char:

;      bl - modules to read counter
;

read_number:
        xor     ch, ch              ;set bh and bl to 0
        mov     bl, 7

read_number_loop:
        call    read_bar
        test    bl, bl           
        dec     bl
        jnz     read_number_loop 
        ret        

        

;       ch - buffer of currently collected values
;       bl - module width counter
;       bh - symbol currently being read - 7 bits


read_bar:
        push    ebx                  ;saving counters
        xor     ebx, ebx
        mov     bl, dh               ;store the amount of bits per module into a counter

byte_check:                          ;load new byte if byte counter hit 0
        test    ah, ah
        dec     ah
        jz      get_byte

skip_module:
        dec     bl
        test    bl, bl
        jnz     byte_check

module_value:
        shl     ch, 1
        jnc     skip_module
        inc     ch                  ;if not zero set current read to 1

read_finished:
        pop     ebx
        ret

get_byte:
        mov     ah, 8
        mov     cl, BYTE[edi]   
        inc     edi
        jmp     byte_check



        ; epilogue
        pop edi
        pop esi
        pop ebx
        pop ebp
        ret
