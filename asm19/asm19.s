global _start

section .data
    ; Adresse + port
    sockaddr: 
        dw 2                  ; AF_INET
        dw 0x3905             ; Port 1337 en big endian (0x0539 → 1337 décimal)
        dd 0x0100007F         ; 127.0.0.1
        dq 0                  ; padding

    hello_msg db 'Hello, client!',10
    hello_len equ $-hello_msg

    logfile db "server.log",0
    log_prefix db "Hello, Client",0
    newline db 10

section .bss
    sock resq 1
    client_sock resq 1
    buf resb 256
    client_count resq 1

section .text
_start:
    ; 1) socket(AF_INET, SOCK_STREAM, 0)
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    mov [sock], rax

    ; 2) bind(sock, &sockaddr, 16)
    mov rdi, [sock]
    lea rsi, [rel sockaddr]
    mov rdx, 16
    mov rax, 49
    syscall

    ; 3) listen(sock, 5)
    mov rdi, [sock]
    mov rsi, 5
    mov rax, 50
    syscall

accept_loop:
    ; 4) accept(sock, NULL, NULL)
    mov rdi, [sock]
    xor rsi, rsi
    xor rdx, rdx
    mov rax, 43
    syscall
    mov [client_sock], rax

    ; 5) lire ce que le client envoie (recvfrom)
    mov rax, 45
    mov rdi, [client_sock]
    lea rsi, [buf]
    mov rdx, 256
    xor r10, r10
    xor r8, r8
    xor r9, r9
    syscall

    ; 6) envoyer la réponse "Hello, client!"
    mov rax, 44
    mov rdi, [client_sock]
    lea rsi, [hello_msg]
    mov rdx, hello_len
    xor r10, r10
    xor r8, r8
    xor r9, r9
    syscall

    ; 7) log "Hello, ClientX" dans server.log
    ; incrémenter compteur
    mov rax, [client_count]
    inc rax
    mov [client_count], rax

    ; ouvrir fichier log en append
    mov rax, 2
    lea rdi, [rel logfile]
    mov rsi, 1089        ; O_WRONLY|O_CREAT|O_APPEND
    mov rdx, 0644
    syscall
    mov r12, rax         ; fd log

    ; écrire "Hello, Client"
    mov rax, 1
    mov rdi, r12
    lea rsi, [rel log_prefix]
    mov rdx, 13
    syscall

    ; écrire numéro du client (en ascii)
    mov rax, [client_count]
    call itoa
    mov rax, 1
    mov rdi, r12
    lea rsi, [buf]
    mov rdx, rbx
    syscall

    ; écrire newline
    mov rax, 1
    mov rdi, r12
    lea rsi, [rel newline]
    mov rdx, 1
    syscall

    ; close fichier
    mov rax, 3
    mov rdi, r12
    syscall

    ; 8) fermer socket client
    mov rax, 3
    mov rdi, [client_sock]
    syscall

    jmp accept_loop

; ===== itoa: convertit RAX → string dans [buf], longueur dans RBX =====
itoa:
    mov rcx, 10
    lea rdi, [buf+64]    ; écrire à l’envers
.convert:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test rax, rax
    jnz .convert
    ; calcul longueur
    mov rbx, buf+64
    sub rbx, rdi
    ; décaler string au début de buf
    lea rsi, [buf]
    mov rdx, rbx
    rep movsb
    ret
