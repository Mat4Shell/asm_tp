section .bss
    buffer  resb 256     
    outbuf  resb 256 

section .text
    global _start

_start:
    mov rax, 0           
    mov rdi, 0      
    mov rsi, buffer
    mov rdx, 256
    syscall
    mov rbx, rax         


    dec rbx
    cmp byte [buffer + rbx], 10
    jne .no_newline

    jmp .have_len

.no_newline:
    inc rbx

.have_len:
    cmp rbx, 0
    jz .print_empty

    xor rcx, rcx          
    mov rdx, rbx         

.reverse_loop:
    dec rbx
    mov al, [buffer + rbx]
    mov [outbuf + rcx], al
    inc rcx
    test rbx, rbx
    jnz .reverse_loop

    mov byte [outbuf + rcx], 10
    inc rcx

    mov rax, 1
    mov rdi, 1
    mov rsi, outbuf
    mov rdx, rcx
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

.print_empty:
    mov byte [outbuf], 10
    mov rax, 1
    mov rdi, 1
    mov rsi, outbuf
    mov rdx, 1
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall
