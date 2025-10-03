section .bss
    buffer resb 256        ; buffer pour l'entrée
    outbuf resb 32         ; buffer pour le résultat

section .text
    global _start

_start:
    ; read stdin -> buffer
    mov rax, 0             ; syscall read
    mov rdi, 0             ; fd = stdin
    mov rsi, buffer
    mov rdx, 256
    syscall

    ; RCX = compteur voyelles
    xor rcx, rcx
    xor rbx, rbx           ; index i = 0

.count_loop:
    mov al, [buffer + rbx]
    cmp al, 0
    je .done_count
    cmp al, 10             ; ignorer newline
    je .next_char

    ; vérifier voyelles minuscules
    cmp al, 'a'
    je .inc_vowel
    cmp al, 'e'
    je .inc_vowel
    cmp al, 'i'
    je .inc_vowel
    cmp al, 'o'
    je .inc_vowel
    cmp al, 'u'
    je .inc_vowel
    cmp al, 'y'
    je .inc_vowel

    ; vérifier voyelles majuscules
    cmp al, 'A'
    je .inc_vowel
    cmp al, 'E'
    je .inc_vowel
    cmp al, 'I'
    je .inc_vowel
    cmp al, 'O'
    je .inc_vowel
    cmp al, 'U'
    je .inc_vowel
    cmp al, 'Y'
    je .inc_vowel

    jmp .next_char

.inc_vowel:
    inc rcx

.next_char:
    inc rbx
    jmp .count_loop

.done_count:
    ; RCX contient le nombre de voyelles
    mov rax, rcx

    ; convertir en string décimale
    mov rsi, outbuf + 31
    mov byte [rsi], 10       ; newline
    dec rsi
    mov rbx, 10
    cmp rax, 0
    jne .conv_loop
    mov byte [rsi], '0'
    dec rsi
    jmp .conv_done

.conv_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test rax, rax
    jnz .conv_loop

.conv_done:
    inc rsi
    mov rdx, outbuf+32
    sub rdx, rsi
    mov rax, 1
    mov rdi, 1
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
