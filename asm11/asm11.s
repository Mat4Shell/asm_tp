section .bss
    buffer resb 256   
    outbuf resb 32     

section .text
    global _start

_start:
    mov rax, 0           
    mov rdi, 0      
    mov rsi, buffer
    mov rdx, 256
    syscall

    xor rcx, rcx
    xor rbx, rbx          

.count_loop:
    mov al, [buffer + rbx]
    cmp al, 0
    je .done_count
    cmp al, 10           
    je .next_char

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
    mov rax, rcx

    mov rsi, outbuf + 31
    mov byte [rsi], 10   
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
