; asm17.asm
; Caesar cipher implementation (x86-64 Linux)
; Usage:
;   echo "hello" | ./asm17 3
; Exit codes:
;   0 -> success
;   1 -> no shift param
;   2 -> invalid shift param

section .bss
    buf resb 256      ; buffer pour lecture et sortie

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
    mov rsi, [rsp + 16]   ; pointer sur shift string

    ; convertir shift en entier (gestion signe)
    xor rax, rax
    xor rbx, rbx          ; rbx = shift
    xor rcx, rcx
    mov bl, 0              ; flag négatif = 0

    mov dl, byte [rsi + rcx]
    cmp dl, '-'
    jne .skip_neg
    mov bl, 1
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
    test bl, bl
    jz .shift_ok
.shift_ok:

    ; lire stdin
    mov rax, 0            ; sys_read
    mov rdi, 0            ; stdin
    mov rsi, buf
    mov rdx, 256
    syscall
    cmp rax, 0
    jle .done             ; rien lu, exit 0
    mov rcx, rax          ; rcx = nb octets lus

    ; appliquer Caesar
    xor rdx, rdx
    mov rsi, buf
.cipher_loop:
    cmp rdx, rcx
    jge .write_out
    mov al, [rsi + rdx]

    ; minuscules ?
    cmp al, 'a'
    jb .check_upper
    cmp al, 'z'
    ja .check_upper
    sub al, 'a'
    mov r8, rbx
    ; modulo 26 wrap
    mov r9, 26
    add al, r8b
    xor r10b, r10b
.mod_loop_lower:
    cmp al, 26
    jb .done_lower
    sub al, 26
    jmp .mod_loop_lower
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
    mov r9, 26
    add al, r8b
    xor r10b, r10b
.mod_loop_upper:
    cmp al, 26
    jb .done_upper
    sub al, 26
    jmp .mod_loop_upper
.done_upper:
    add al, 'A'

.store_char:
    mov [rsi + rdx], al
    inc rdx
    jmp .cipher_loop

.write_out:
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
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
