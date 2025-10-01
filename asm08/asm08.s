global _start
section .bss
    result resb 64

section .text
_start:

    mov rsi, [rsp + 16]
    cmp rsi, 0
    je error

    mov rax, 0
    mov rcx, 0

convert_int:
    movzx rbx, byte [rsi + rcx] 
    test rbx, rbx    
    jz sum

    cmp rbx, 10       
    je sum

    cmp rbx, '0'
    jb is_letter          
    cmp rbx, '9'
    ja is_letter            

    sub rbx, '0'         
    imul rax, rax, 10        
    add rax, rbx          
    inc rcx                  
    jmp convert_int

sum:
    mov rbx, 0
    mov rcx, 1

sum_loop:
    cmp rcx, rax
    jge print
    add rbx, rcx
    inc rcx
    jmp sum_loop


print:
    mov rsi, result
    add rsi, 63
    mov byte[rsi], 0
    mov rax, rbx


convert_to_string:
    mov rdx, 0
    mov r8, 10
    div r8

    add dl, '0'
    dec rsi
    dec rsi
    mov byte[rsi], dl

    test rax, rax
    jnz convert_to_string

    mov rax, 1
    mov rdi, 1
    mov rdx, 64
    mov rsi, result
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

is_letter:
    mov rax, 60
    mov rdi, 2
    syscall

error:
    mov rax, 0
    mov rdi, 0

    mov rax, 60
    mov rdi, 1
    syscall