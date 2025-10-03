; asm20.asm
; Multi-client TCP server simple
; Usage: ./asm20
; Listen on port 4242, handle simple commands: PING, ECHO, REVERSE, EXIT

section .data
    port dw 4242
    backlog equ 5
    prompt db "Type a command: ", 0
    prompt_len equ $ - prompt
    pong_msg db "PONG", 10, 0
    goodbye_msg db "Goodbye!", 10, 0
    buf resb 1024

section .text
    global _start

_start:
    ; socket(AF_INET, SOCK_STREAM, 0)
    mov rax, 41        ; sys_socket
    mov rdi, 2         ; AF_INET
    mov rsi, 1         ; SOCK_STREAM
    xor rdx, rdx       ; protocol = 0
    syscall
    cmp rax, 0
    jl .exit
    mov r12, rax       ; server socket fd

    ; bind
    mov rdi, r12       ; fd
    lea rsi, [rel sockaddr_in]
    mov rdx, 16        ; sizeof(sockaddr_in)
    mov rax, 49        ; sys_bind
    syscall
    cmp rax, 0
    jl .exit

    ; listen
    mov rdi, r12
    mov rsi, backlog
    mov rax, 50        ; sys_listen
    syscall
    cmp rax, 0
    jl .exit

.accept_loop:
    ; accept
    mov rax, 43        ; sys_accept
    mov rdi, r12       ; server fd
    xor rsi, rsi       ; addr ptr NULL
    xor rdx, rdx       ; addrlen NULL
    syscall
    cmp rax, 0
    jl .accept_loop    ; retry on error
    mov r13, rax       ; client fd

.client_loop:
    ; send prompt
    mov rax, 1         ; sys_write
    mov rdi, r13
    lea rsi, [rel prompt]
    mov rdx, prompt_len
    syscall

    ; read input
    mov rax, 0         ; sys_read
    mov rdi, r13
    lea rsi, [rel buf]
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle .close_client  ; client closed

    ; rax = bytes read, null terminate
    mov rcx, rax
    lea rbx, [buf + rcx]
    mov byte [rbx], 0

    ; check for EXIT
    lea rsi, [rel buf]
    mov rdi, rax
    call check_exit
    cmp rax, 1
    je .send_goodbye

    ; check for PING
    lea rsi, [rel buf]
    mov rdi, rax
    call check_ping
    cmp rax, 1
    je .send_pong

    ; check for REVERSE
    lea rsi, [rel buf]
    mov rdi, rax
    call check_reverse
    cmp rax, 1
    je .send_reverse

    ; check for ECHO
    lea rsi, [rel buf]
    mov rdi, rax
    call check_echo
    cmp rax, 1
    je .send_echo

    jmp .client_loop

.send_goodbye:
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel goodbye_msg]
    mov rdx, 9
    syscall
    jmp .close_client

.send_pong:
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel pong_msg]
    mov rdx, 5
    syscall
    jmp .client_loop

.send_reverse:
    ; reverse string in-place
    lea rsi, [rel buf]
    mov rdi, rax       ; rdi = len
    call reverse_string
    ; write reversed string
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel buf]
    mov rdx, rdi       ; len
    syscall
    jmp .client_loop

.send_echo:
    ; write buf as-is
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel buf]
    mov rdx, rdi
    syscall
    jmp .client_loop

.close_client:
    mov rax, 3
    mov rdi, r13
    syscall
    jmp .accept_loop

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

; ------------------ helper functions ------------------

; check_exit: returns rax=1 if input is "EXIT\n"
check_exit:
    ; simple compare first 5 bytes
    mov rbx, rsi
    mov al, byte [rbx]
    cmp al, 'E'
    jne .fail_exit
    mov al, byte [rbx+1]
    cmp al, 'X'
    jne .fail_exit
    mov al, byte [rbx+2]
    cmp al, 'I'
    jne .fail_exit
    mov al, byte [rbx+3]
    cmp al, 'T'
    jne .fail_exit
    mov al, byte [rbx+4]
    cmp al, 10
    jne .fail_exit
    mov rax, 1
    ret
.fail_exit:
    xor rax, rax
    ret

; check_ping: returns rax=1 if "PING\n"
check_ping:
    mov rbx, rsi
    mov al, byte [rbx]
    cmp al, 'P'
    jne .fail_ping
    mov al, byte [rbx+1]
    cmp al, 'I'
    jne .fail_ping
    mov al, byte [rbx+2]
    cmp al, 'N'
    jne .fail_ping
    mov al, byte [rbx+3]
    cmp al, 'G'
    jne .fail_ping
    mov al, byte [rbx+4]
    cmp al, 10
    jne .fail_ping
    mov rax, 1
    ret
.fail_ping:
    xor rax, rax
    ret

; check_reverse: returns rax=1 if "REVERSE "
check_reverse:
    mov rbx, rsi
    mov al, byte [rbx]
    cmp al, 'R'
    jne .fail_rev
    mov al, byte [rbx+1]
    cmp al, 'E'
    jne .fail_rev
    mov al, byte [rbx+2]
    cmp al, 'V'
    jne .fail_rev
    mov al, byte [rbx+3]
    cmp al, 'E'
    jne .fail_rev
    mov al, byte [rbx+4]
    cmp al, 'R'
    jne .fail_rev
    mov al, byte [rbx+5]
    cmp al, 'S'
    jne .fail_rev
    mov al, byte [rbx+6]
    cmp al, 'E'
    jne .fail_rev
    mov al, byte [rbx+7]
    cmp al, ' '
    jne .fail_rev
    mov rax, 1
    ret
.fail_rev:
    xor rax, rax
    ret

; check_echo: returns rax=1 if "ECHO "
check_echo:
    mov rbx, rsi
    mov al, byte [rbx]
    cmp al, 'E'
    jne .fail_echo
    mov al, byte [rbx+1]
    cmp al, 'C'
    jne .fail_echo
    mov al, byte [rbx+2]
    cmp al, 'H'
    jne .fail_echo
    mov al, byte [rbx+3]
    cmp al, 'O'
    jne .fail_echo
    mov al, byte [rbx+4]
    cmp al, ' '
    jne .fail_echo
    mov rax, 1
    ret
.fail_echo:
    xor rax, rax
    ret

; reverse_string:
; rsi = ptr start, rdi = len
reverse_string:
    mov r8, rdi       ; save len
    dec r8
    xor r9, r9        ; start index
.rev_loop:
    cmp r9, r8
    jge .rev_done
    mov al, [rsi + r9]
    mov bl, [rsi + r8]
    mov [rsi + r9], bl
    mov [rsi + r8], al
    inc r9
    dec r8
    jmp .rev_loop
.rev_done:
    mov rdi, rdi      ; return length in rdi
    ret

; ------------------ sockaddr_in structure ------------------
section .data
sockaddr_in:
    dw 2              ; AF_INET = 2
    dw 0              ; port placeholder (will fill dynamically)
    dd 0              ; INADDR_ANY = 0
    dq 0              ; padding
