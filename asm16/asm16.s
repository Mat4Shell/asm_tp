section .text
    global _start

_start:
    mov rax, [rsp]         
    cmp rax, 2
    jl .no_param

    mov rdi, [rsp + 16]    

    mov rax, 2            
    mov rsi, 2          
    xor rdx, rdx         
    syscall
    cmp rax, 0
    jl .open_failed
    mov r12, rax          

    mov rax, 8            
    mov rdi, r12          
    xor rsi, rsi        
    mov rdx, 2           
    syscall
    cmp rax, 4
    jb .too_small        
    mov r13, rax          

    mov rax, 9           
    xor rdi, rdi        
    mov rsi, r13         
    mov rdx, 3         
    mov r10, 1           
    mov r8, r12        
    xor r9, r9         
    syscall

    cmp rax, 0
    jl .mmap_failed
    mov rbx, rax          

    mov rcx, 0             
    mov rdx, r13           
    sub rdx, 4             

    mov r9d, 0x37333331

.search_loop:
    cmp rcx, rdx
    ja  .not_found  

    mov eax, dword [rbx + rcx]
    cmp eax, r9d
    jne .next_i

    mov dword [rbx + rcx], 0x4B433448

    mov rax, 60
    xor rdi, rdi
    syscall

.next_i:
    inc rcx
    jmp .search_loop


.not_found:
    mov rax, 60
    mov rdi, 1
    syscall

.too_small:
    mov rax, 60
    mov rdi, 1
    syscall

.open_failed:
    mov rax, 60
    mov rdi, 1
    syscall

.mmap_failed:
    mov rax, 60
    mov rdi, 1
    syscall

.no_param:
    mov rax, 60
    mov rdi, 1
    syscall
