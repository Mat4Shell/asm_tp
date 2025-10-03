; asm17.asm - Caesar cipher correct (shift avance, wrap modulo 26)

section .bss
    buf resb 256

section .data
    newline db 10

section .text
    global _start

_start:
    ; Vérifier argc
    mov rax, [rsp]        ; argc
    cmp rax, 2
    jl .no_param

    ; argv[1] = shift
    mov rsi, [rsp + 16]   ; pointer shift string

    ; convertir shift en entier
    xor rax, rax
    xor rbx, rbx          ; rbx = shift
    xor rcx, rcx
    xor rdx, rdx          ; flag négatif
    mov dl, byte [rsi + rcx]
    cmp dl, '-'
    jne .skip_neg
    mov dl, 1
    inc rcx
.skip_neg:
.convert_shift:
    mov al, byte [rsi + rcx]
    cmp al, 0
    je .shift_done
    cmp al, '0'
    jb .bad_shift
    cmp al, '9'
    ja .bad_shift
    sub al, '0'
    imul rbx, rbx, 10
    add rbx, rax
    inc rcx
    jmp .convert_shift
.shift_done:
    test dl, dl
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
    xor rdx, rdx          ; idx

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
    mov r8, rbx
    add al, r8b
    ; wrap modulo 26
    mov bl, 26
.wrap_lower:
    cmp al, 26
    jb .done_lower
    sub al, 26
    jmp .wrap_lower
.done_lower:
    add al, 'a'
    jmp .store_char

.check_upper:
    cmp al, 'A'
    jb .store_char
    cmp al, 'Z'
    ja .store_char
    sub al, 'A'
    mov r8, rbx
    add al, r8b
    mov bl, 26
.wrap_upper:
    cmp al, 26
    jb .done_upper
    sub al, 26
    jmp .wrap_upper
.done_upper:
    add al, 'A'

.store_char:
    mov [buf + rdx], al
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
