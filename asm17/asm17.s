section .bss
    buf resb 256

section .data
    newline db 10

section .text
    global _start

_start:
    ; Vérifier argc
    mov rax, [rsp]
    cmp rax, 2
    jl .no_param

    mov rsi, [rsp + 16]   ; argv[1] = shift

    ; convertir shift en entier
    xor rbx, rbx          ; shift
    xor rcx, rcx
    xor rdx, rdx          ; flag négatif
    mov dl, byte [rsi + rcx]
    cmp dl, '-'
    jne .skip_neg
    mov dh, 1
    inc rcx
.skip_neg:
.convert_shift:
    mov dl, byte [rsi + rcx]
    cmp dl, 0
    je .shift_done
    cmp dl, '0'
    jb .bad_shift
    cmp dl, '9'
    ja .bad_shift
    sub dl, '0'
    imul rbx, rbx, 10
    add rbx, rdx
    inc rcx
    jmp .convert_shift
.shift_done:
    test dh, dh
    jz .shift_ok
    neg rbx
.shift_ok:

    ; lire stdin
    mov rax, 0
    mov rdi, 0
    mov rsi, buf
    mov rdx, 256
    syscall
    cmp rax, 0
    jle .done
    mov rcx, rax          ; nb octets lus
    xor rdx, rdx

.cipher_loop:
    cmp rdx, rcx
    jge .write_out
    mov al, [buf + rdx]

    ; minuscules ?
    cmp al, 'a'
    jb .check_upper
    cmp al, 'z'
    ja .check_upper
    sub al, 'a'
    mov r8, al
    add r8b, bl
    add r8b, 26
    mov r9b, 26
    xor r10b, r10b
.mod_lower:
    cmp r8b, 26
    jb .done_lower
    sub r8b, 26
    jmp .mod_lower
.done_lower:
    add r8b, 'a'
    mov [buf + rdx], r8b
    jmp .next_char

.check_upper:
    cmp al, 'A'
    jb .next_char
    cmp al, 'Z'
    ja .next_char
    sub al, 'A'
    mov r8, al
    add r8b, bl
    add r8b, 26
    mov r9b, 26
.mod_upper:
    cmp r8b, 26
    jb .done_upper
    sub r8b, 26
    jmp .mod_upper
.done_upper:
    add r8b, 'A'
    mov [buf + rdx], r8b

.next_char:
    inc rdx
    jmp .cipher_loop

.write_out:
    mov rax, 1
    mov rdi, 1
    mov rsi, buf
    mov rdx, rcx
    syscall

.done:
    mov rax, 60
    xor rdi, rdi
    syscall

.no_param:
    mov rax, 60
    mov rdi, 1
    syscall

.bad_shift:
    mov rax, 60
    mov rdi, 2
    syscall
