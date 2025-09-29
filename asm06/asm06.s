global _start
_start:
section .bss
    result resb 20
section .text
    mov rsi, [rsp + 16]
    cmp rsi, 0
    je error

    mov rdi, [rsp + 24]
    cmp rdi, 0
    je error



convert_to_int:
    movzx rbx, byte[rsi + rcx]
    test rbx, rbx
    jz second_arg
    cmp rbx, 10
    je second_arg

    cmp rbx, 0x2d
    je boolean

    cmp rbx, 0x30
    jb is_letter
    cmp rbx, 0x39
    ja is_letter 

    sub rbx, '0'
    imul rax, rax, 10
    add rax, rbx
    inc rcx
    jmp convert_to_int

second_arg:
    test r11, r11
    jz no_neg
    neg rax

no_neg:
    mov rbx, rax
    xor rax, rax
    xor rcx, rcx

convert_to_int2:
    movzx r10, byte[rdi + rcx]
    test r10, r10
    jz addition
    cmp r10, 10
    je addition

    cmp r10, 0x2d
    je boolean2

    cmp r10, 0x30
    jb is_letter
    cmp r10, 0x39
    ja is_letter 

    sub r10, '0'
    imul rax, rax, 10
    add rax, r10
    inc rcx
    jmp convert_to_int2

addition:
    add rax, rbx
    ;add \0 at the end of the buffer
    mov rsi, result
    add rsi, 19
    mov byte[rsi], 0
    cmp r11, 1
    neg rax

    jmp convert_to_string

convert_to_string:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    add dl, '0'
    dec rsi
    mov byte[rsi], dl
    test rax, rax
    jnz convert_to_string

    mov rax, 1
    mov rdi, 1
    mov rdx, 20
    syscall

; strlen:
;     cmp byte[rsi + rcx], 0
;     je print
;     inc rcx
;     jmp strlen

exit:
    xor rax, rax
    xor rdi, rdi

    mov rax, 60
    xor rdi, rdi
    syscall

error:
    xor rax, rax
    xor rdi, rdi

    mov rax, 60
    mov rdi, 1
    syscall

boolean:
    mov r11, 1
    neg rbx
    jmp convert_to_int2

boolean2:
    mov r12, 1
    neg r10
    jmp addition


is_letter:
    xor rax, rax
    xor rdi, rdi

    mov rax, 60
    mov rdi, 2
    syscall