section .bss
    buffer  resb 256       

section .text
    global _start

_start:
    mov rax, 0            
    mov rdi, 0          
    mov rsi, buffer
    mov rdx, 256
    syscall
    mov rcx, rax         

    cmp rcx, 0
    je .palindrome     

    dec rcx
    cmp byte [buffer + rcx], 10
    jne .no_newline
    jmp .have_len

.no_newline:
    inc rcx

.have_len:
    cmp rcx, 1
    jbe .palindrome

    xor rbx, rbx        
    mov rdx, rcx
    dec rdx             

.compare_loop:
    mov al, [buffer + rbx] 
    mov bl, [buffer + rdx] 
    cmp al, bl
    jne .not_palindrome

    inc rbx
    dec rdx
    cmp rbx, rdx
    jl .compare_loop

.palindrome:
    mov rax, 60
    xor rdi, rdi
    syscall

.not_palindrome:
    mov rax, 60
    mov rdi, 1
    syscall
