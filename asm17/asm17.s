section .bss
    buf resb 4096   
    out resb 4096  

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl .no_param
    ; argv[1]
    mov rdi, [rsp+16]
    jmp .parse_shift
.no_param:
    xor rsi, rsi     
    jmp .read_stdin

.parse_shift:
    mov rsi, 0      
    mov rbx, rdi     
.next_digit:
    mov al, byte [rbx]
    cmp al, 0
    je .shift_ready
    sub al, '0'
    cmp al, 9
    ja .shift_ready
    imul rsi, rsi, 10
    add rsi, rax
    inc rbx
    jmp .next_digit

.shift_ready:
    mov rax, 26
    xor rdx, rdx
    div rax              
    mov rsi, rdx        

.read_stdin:
    mov rax, 0          
    mov rdi, 0          
    mov rsi, buf
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .exit_ok
    mov r12, rax       

    mov rcx, 0
.loop:
    cmp rcx, r12
    jge .write_out

    mov al, [buf+rcx]

    cmp al, 'a'
    jb .check_upper
    cmp al, 'z'
    ja .check_upper
    sub al, 'a'
    add al, sil     
    mov bl, 26
    div bl           
    add al, 'a'
    mov [out+rcx], al
    jmp .next_char

.check_upper:
    cmp al, 'A'
    jb .no_change
    cmp al, 'Z'
    ja .no_change
    sub al, 'A'
    add al, sil
    mov bl, 26
    div bl
    add al, 'A'
    mov [out+rcx], al
    jmp .next_char

.no_change:
    mov [out+rcx], al

.next_char:
    inc rcx
    jmp .loop

.write_out:
    mov rax, 1         
    mov rdi, 1
    mov rsi, out
    mov rdx, r12
    syscall

.exit_ok:
    mov rax, 60
    xor rdi, rdi
    syscall
