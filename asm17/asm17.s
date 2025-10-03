; asm17.asm
; Caesar cipher implementation
; Exemple :
;   echo "hello" | ./asm17 3   => khoor
;   echo "abcXYZ" | ./asm17 2  => cdeZAB

section .bss
    buf   resb 1024
    shift resq 1

section .text
    global _start

_start:
    ; récupérer argc
    mov rax, [rsp]
    cmp rax, 2
    jl .no_param

    ; argv[1]
    mov rdi, [rsp+16]
    call parse_number
    mov [shift], rax
    jmp .main_loop

.no_param:
    mov qword [shift], 0

; -------------------------
; Lecture/écriture boucle
.main_loop:
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    lea rsi, [buf]
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle .exit_ok
    mov rbx, rax        ; nb octets lus

    xor rcx, rcx
.loop_chars:
    cmp rcx, rbx
    jge .write_out

    mov al, [buf+rcx]
    movzx rdx, al

    ; ----- minuscules -----
    cmp dl, 'a'
    jb .check_upper
    cmp dl, 'z'
    ja .check_upper
    sub dl, 'a'
    mov rax, [shift]
    add rax, rdx
    mov rcx, 26
    xor rdx, rdx
    div rcx          ; rax/26 -> quotient, reste en rdx
    mov dl, dl       ; rdx = reste
    add dl, 'a'
    mov [buf+rcx], dl
    jmp .next_char

.check_upper:
    ; ----- majuscules -----
    cmp dl, 'A'
    jb .store_same
    cmp dl, 'Z'
    ja .store_same
    sub dl, 'A'
    mov rax, [shift]
    add rax, rdx
    mov rcx, 26
    xor rdx, rdx
    div rcx
    mov dl, dl
    add dl, 'A'
    mov [buf+rcx], dl
    jmp .next_char

.store_same:
    mov [buf+rcx], al

.next_char:
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

; --------------------------------
; parse_number: ascii -> int
; IN: rdi = ptr
; OUT: rax = valeur
; si non-digit -> exit(1)
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
