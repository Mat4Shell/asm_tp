; asm13.asm
; Palindrome detection
; Usage: echo "radar" | ./asm13

section .bss
    buffer  resb 256       ; buffer d'entrée

section .text
    global _start

_start:
    ; lire depuis stdin
    mov rax, 0             ; syscall read
    mov rdi, 0             ; fd stdin
    mov rsi, buffer
    mov rdx, 256
    syscall
    mov rcx, rax           ; longueur lue

    ; si rien lu → empty input
    cmp rcx, 0
    je .palindrome         ; par convention, chaîne vide = palindrome

    ; gérer le newline
    dec rcx
    cmp byte [buffer + rcx], 10
    jne .no_newline
    jmp .have_len

.no_newline:
    inc rcx
.have_len:

    ; si longueur <= 1 → palindrome
    cmp rcx, 1
    jbe .palindrome

    ; indices i = 0, j = rcx-1
    xor rbx, rbx           ; rbx = i = début
    mov rdx, rcx
    dec rdx                ; rdx = j = fin

.compare_loop:
    mov al, [buffer + rbx] ; char gauche
    mov bl, [buffer + rdx] ; char droite
    cmp al, bl
    jne .not_palindrome

    inc rbx
    dec rdx
    cmp rbx, rdx
    jl .compare_loop

.palindrome:
    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

.not_palindrome:
    ; exit(1)
    mov rax, 60
    mov rdi, 1
    syscall
