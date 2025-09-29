global _start
_start:

section .text

    mov rsi, [rsp + 16]
    cmp rsi, 1
    jl error
    xor rcx, rcx

strlen:
    cmp byte[rsi + rcx], 0
    je print
    inc rcx
    jmp strlen

print:   
    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

error:
    xor rax, rax
    xor rdi, rdi

    mov rax, 60
    mov rdi, 1
    syscall