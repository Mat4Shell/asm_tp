global _start

section .bss
    input resb 32   

section .text
_start:
    ; read(0, input, 32)
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 32
    syscall

    ; convertir ASCII → entier
    xor rax, rax    
    xor rcx, rcx      
    xor rbx, rbx
    mov rbx, input

.convert_loop:
    movzx r8, byte [rbx + rcx]
    test r8, r8
    jz .end_convert
    cmp r8, 10      
    je .end_convert

    cmp r8, '0'
    jb bad_input
    cmp r8, '9'
    ja bad_input

    sub r8, '0'
    imul rax, rax, 10
    add rax, r8

    inc rcx
    jmp .convert_loop

.end_convert:
    mov rsi, rax    

    ; n <= 1 → non premier
    cmp rsi, 2
    jl not_prime

    ; si n == 2 → premier
    cmp rsi, 2
    je is_prime

    ; boucle de test de primalité
    mov rcx, 2     

.prime_loop:
    mov rax, rsi
    xor rdx, rdx
    div rcx   
    test rdx, rdx
    jz not_prime    

    inc rcx
    mov rax, rcx
    imul rax, rax    
    cmp rax, rsi
    jle .prime_loop  

is_prime:
    mov rax, 60
    xor rdi, rdi   
    syscall

not_prime:
    mov rax, 60
    mov rdi, 1     
    syscall

bad_input:
    mov rax, 60
    mov rdi, 2       
    syscall
