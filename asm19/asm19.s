global _start

section .data
listen_msg db "listening on port 1337",10
listen_len equ $-listen_msg

filename   db "messages",0

section .bss
sockaddr   resb 16
buf        resb 128
timeout_tv resb 16

section .text
_start:
    ; 1. socket(AF_INET, SOCK_DGRAM, 0)
    mov rax, 41
    mov rdi, 2          ; AF_INET
    mov rsi, 2          ; SOCK_DGRAM
    xor rdx, rdx
    syscall
    mov r12, rax        ; save sockfd

    ; 2. bind(sock, sockaddr, 16)
    lea rdi, [sockaddr]
    mov word [rdi], 2              ; AF_INET
    mov word [rdi+2], 0x3905       ; htons(1337) = 0x3905 en little endian
    xor eax, eax
    mov dword [rdi+4], eax         ; INADDR_ANY (0.0.0.0)
    mov qword [rdi+8], 0           ; sin_zero

    mov rax, 49       ; syscall: bind
    mov rdi, r12
    lea rsi, [sockaddr]
    mov rdx, 16
    syscall

    ; 3. afficher "listening on port 1337"
    mov rax, 1
    mov rdi, 1
    lea rsi, [listen_msg]
    mov rdx, listen_len
    syscall

    ; 4. setsockopt timeout pour recvfrom (1s)
    mov qword [timeout_tv], 1      ; tv_sec = 1
    xor qword [timeout_tv+8], rax ; tv_usec = 0
    mov rax, 54                    ; setsockopt
    mov rdi, r12
    mov rsi, 1                     ; SOL_SOCKET
    mov rdx, 20                    ; SO_RCVTIMEO
    lea r10, [timeout_tv]
    mov r8, 16
    syscall

    ; 5. openat(AT_FDCWD, "messages", O_WRONLY|O_CREAT|O_APPEND, 0644)
    mov rax, 257            ; syscall: openat
    mov rdi, -100           ; AT_FDCWD
    lea rsi, [filename]     ; chemin
    mov rdx, 577            ; O_WRONLY|O_CREAT|O_APPEND
    mov r10, 0777           ; permissions
    syscall
    
    mov r14, rax            ; fd

.loop:
    ; 4. recvfrom(sock, buf, 128, 0, NULL, NULL)
    mov rax, 45
    mov rdi, r12
    lea rsi, [buf]
    mov rdx, 128
    xor r10, r10
    xor r8, r8
    xor r9, r9
    syscall
    cmp rax, 0
    jle .exit          ; si erreur ou rien reçu → exit

    mov r13, rax       ; sauvegarder taille lue


    ; 6. write(fd, buf, taille)
    mov rax, 1
    mov rdi, r14
    lea rsi, [buf]
    mov rdx, r13
    syscall

    ; 7. close(fd)
    mov rax, 3
    mov rdi, r14
    syscall

    jmp .loop


.exit:
    mov rax, 3
    mov rdi, r14
    syscall

    mov rax, 3
    mov rdi, r12
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall