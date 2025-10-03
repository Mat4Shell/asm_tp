; asm12.asm
; Reverse string
; Usage: echo "Bonjour" | ./asm12

section .bss
    buffer  resb 256       ; buffer d'entrée
    outbuf  resb 256       ; buffer sortie inversée

section .text
    global _start

_start:
    ; read stdin -> buffer
    mov rax, 0             ; syscall read
    mov rdi, 0             ; fd = stdin
    mov rsi, buffer
    mov rdx, 256
    syscall
    mov rbx, rax           ; longueur lue (inclut éventuellement \n)

    ; retirer le newline si présent
    dec rbx
    cmp byte [buffer + rbx], 10
    jne .no_newline
    ; si \n trouvé, on garde rbx comme longueur utile
    jmp .have_len

.no_newline:
    inc rbx
.have_len:

    ; si longueur = 0, sortie directe
    cmp rbx, 0
    jz .print_empty

    ; inverser la chaîne
    xor rcx, rcx           ; index avant
    mov rdx, rbx           ; longueur

.reverse_loop:
    dec rbx
    mov al, [buffer + rbx]
    mov [outbuf + rcx], al
    inc rcx
    test rbx, rbx
    jnz .reverse_loop

    ; ajouter '\n'
    mov byte [outbuf + rcx], 10
    inc rcx

    ; afficher la sortie
    mov rax, 1
    mov rdi, 1
    mov rsi, outbuf
    mov rdx, rcx
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

.print_empty:
    ; juste afficher un newline
    mov byte [outbuf], 10
    mov rax, 1
    mov rdi, 1
    mov rsi, outbuf
    mov rdx, 1
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
