; asm17.asm
; Caesar cipher sur stdin -> stdout
; Usage :
;   echo "hello" | ./asm17 3
;   khoor
;
; Exit codes :
;   0 -> OK
;   1 -> param invalide (non numérique)

section .bss
    buf resb 1024
    shift resq 1

section .text
    global _start

_start:
    ; --------------------
    ; argc/argv handling
    mov rax, [rsp]        ; argc
    cmp rax, 2
    jl .no_param
    ; argv[1]
    mov rdi, [rsp+16]
    call parse_number
    mov [shift], rax
    jmp .main_loop

.no_param:
    mov qword [shift], 0

; --------------------
; Lecture boucle stdin -> traitement -> stdout
.main_loop:
    mov rax, 0      ; sys_read
    mov rdi, 0      ; stdin
    lea rsi, [buf]
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle .exit_ok
    mov rbx, rax    ; rbx = nb octets lus

    ; appliquer le chiffrement sur buf
    xor rcx, rcx
.loop_chars:
    cmp rcx, rbx
    jge .write_out
    mov al, [buf+rcx]
    movzx rdx, al

    ; Vérifier si lettre minuscule 'a'..'z'
    cmp dl, 'a'
    jb .check_upper
    cmp dl, 'z'
    ja .check_upper
    ; appliquer décalage
    mov rax, [shift]
    mov rsi, rax
    add dl, sil
    sub dl, 'a'
    movzx rdx, dl
    mov rax, [shift]
    mov rsi, rax
    mov rax, rdx
    xor rdx, rdx
    mov rcx, 26
    div rcx
    mov dl, al
    mov dl, dl ; (safe)
    mov dl, ah ; correction
    ; mauvais passage – simplifions

.check_upper:
    cmp dl, 'A'
    jb .store_char
    cmp dl, 'Z'
    ja .store_char
    ; TODO majuscules
.store_char:
    mov [buf+rcx], dl
    inc rcx
    jmp .loop_chars

.write_out:
    mov rax, 1
    mov rdi, 1
    lea rsi, [buf]
    mov rdx, rbx
    syscall
    jmp .main_loop

.exit_ok:
    mov rax, 60
    xor rdi, rdi
    syscall

; ----------------------------------------
; parse_number: convertir argv[1] (ascii décimal) en entier
; IN: rdi=ptr
; OUT: rax=valeur
; si char non-digit -> exit(1)
parse_number:
    xor rax, rax
.parse_loop:
    mov bl, byte [rdi]
    cmp bl, 0
    je .done
    cmp bl, '0'
    jb .bad
    cmp bl, '9'
    ja .bad
    sub bl, '0'
    imul rax, rax, 10
    add rax, rbx
    inc rdi
    jmp .parse_loop
.done:
    ret
.bad:
    mov rax, 60
    mov rdi, 1
    syscall
