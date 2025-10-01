section .bss
    numbuf  resb 32
    outbuf  resb 64

section .data
    newline db 10

section .text
    global _start

_start:
    mov rbx, [rsp]           ; argc
    cmp rbx, 2
    jl usage

    mov rsi, [rsp+16]        ; argv[1]
    mov rdi, [rsi]           ; lire premier octet
    cmp dil, '-'             ; option "-b" ?
    jne default_hex

    ; si -b, vérifier qu'on a bien un 2ème argument
    cmp rbx, 3
    jl usage

    ; argv[2]
    mov rsi, [rsp+24]
    mov rdx, 2               ; mode = binaire
    jmp parse_number

default_hex:
    mov rdx, 16              ; mode = hex
    mov rsi, [rsp+16]        ; argv[1]


parse_number:
    xor rax, rax
    xor rcx, rcx

.parse_loop:
    mov bl, byte [rsi + rcx]
    cmp bl, 0
    je convert_done
    sub bl, '0'
    cmp bl, 9
    ja usage
    imul rax, rax, 10
    add rax, rbx
    inc rcx
    jmp .parse_loop

convert_done:
    ; RAX contient le nombre
    cmp rdx, 16
    je to_hex
    cmp rdx, 2
    je to_bin


to_hex:
    mov rcx, outbuf + 63     ; pointeur fin buffer
    mov byte [rcx], 0
.hex_loop:
    xor rdx, rdx
    mov rbx, 16
    div rbx
    cmp dl, 9
    jbe .digit
    add dl, 'A' - 10
    jmp .store
.digit:
    add dl, '0'
.store:
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .hex_loop

    jmp print_and_exit

to_bin:
    mov rcx, outbuf + 63
    mov byte [rcx], 0
.bin_loop:
    xor rdx, rdx
    mov rbx, 2
    div rbx
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .bin_loop

    jmp print_and_exit


print_and_exit:
    mov rdx, outbuf + 63
    sub rdx, rcx
    mov rsi, rcx
    mov rax, 1
    mov rdi, 1
    syscall

    ; '\n'
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall


usage:
    mov rax, 60
    mov rdi, 1
    syscall