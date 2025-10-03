section .data
    msg db "Hello Universe!", 10  
    msglen equ $ - msg

section .text
    global _start

_start:
    mov rbx, [rsp]      
    cmp rbx, 2
    jl .no_param

    mov rsi, [rsp + 16]   

    mov rax, 2           
    mov rdi, rsi          
    mov rsi, 0101o      
    mov rdx, 0777o      
    syscall

    cmp rax, 0
    jl .error          

    mov rdi, rax
    mov rax, 1        
    mov rsi, msg
    mov rdx, msglen
    syscall

    mov rax, 3         
    mov rdi, rdi
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

.no_param:
    mov rax, 60
    mov rdi, 1         
    syscall

.error:
    mov rax, 60
    mov rdi, 2            
    syscall
