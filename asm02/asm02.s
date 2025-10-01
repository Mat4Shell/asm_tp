global _start
_start:

section .data
    text db '1337', 10

section .bss
    input resb 4
        
section .text

    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 4
    syscall

    mov al, byte [input]
    cmp al, '4'
    jne not_equal

    mov al, byte [input + 1]
    cmp al, '2'
    jne not_equal

    mov al, byte [input + 2]
    cmp al, 10
    jne not_equal

    xor rax, rax
    xor rdi, rdi
    xor rsi, rsi
    
    mov rax, 1
    mov rdi, 1
    mov rsi, text
    mov rdx, 10
    syscall

    mov rax, 60
    xor rdi, rdi
    xor rsi, rsi
    syscall

not_equal:
    xor rax, rax
    xor rdi, rdi

    mov rax, 60
    mov rdi, 1
    syscall