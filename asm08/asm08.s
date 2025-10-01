; asm08: Sum of Integers below N
; Usage: ./asm08 N
; Example: ./asm08 5  -> 10

global _start

section .data
    newline db 10
    newline_len equ $ - newline

section .bss
    res resb 32

section .text

_start:
    ; argc dans rdi, argv dans rsi
    mov rdi, [rsp]            ; argc
    cmp rdi, 2
    jl no_param               ; si pas d'argument → 0 direct

    mov rsi, [rsp+16]         ; argv[1]
    call str_to_int           ; convertit string → rax
    mov rbx, rax              ; rbx = N
    cmp rbx, 1
    jle print_zero            ; si N <= 1 → 0

    ; somme de 1 à N-1
    xor rcx, rcx              ; rcx = i
    xor rax, rax              ; rax = somme
sum_loop:
    inc rcx                   ; i++
    cmp rcx, rbx
    jge sum_done
    add rax, rcx              ; somme += i
    jmp sum_loop
sum_done:
    ; imprimer la somme
    mov rsi, res
    call int_to_str
    mov rdx, rsi
    mov rsi, res
    mov rdi, 1
    mov rax, 1
    syscall

    ; retour à la ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, newline_len
    syscall

    jmp exit_ok

print_zero:
    mov rax, '0'
    mov [res], al
    mov rax, 1
    mov rdi, 1
    mov rsi, res
    mov rdx, 1
    syscall

    ; retour à la ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, newline_len
    syscall
    jmp exit_ok

no_param:
    jmp print_zero

; ---- fonctions ----

; str_to_int: convertit une string décimale → int
; entrée: rsi pointe sur string
; sortie: rax = valeur
str_to_int:
    xor rax, rax
.str_loop:
    mov bl, byte [rsi]
    cmp bl, 0
    je .done
    cmp bl, '0'
    jl .done
    cmp bl, '9'
    jg .done
    sub bl, '0'
    imul rax, rax, 10
    add rax, rbx
    inc rsi
    jmp .str_loop
.done:
    ret

; int_to_str: convertit rax en string ASCII
; entrée: rax = entier, rsi = buffer
; sortie: buffer rempli, rsi = longueur
int_to_str:
    mov rcx, 10
    mov rbx, rsi
    add rsi, 31
    mov byte [rsi], 0
.convert:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .convert
    mov rdx, rbx
    mov rcx, rsi
    sub rdx, rcx
    mov rsi, rcx
    ret

exit_ok:
    mov rax, 60
    xor rdi, rdi
    syscall
