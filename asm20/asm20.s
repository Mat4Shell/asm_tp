; asm20.asm
; Multi-client TCP server (NASM x86-64)
; Listens on port 4242. For each client:
; - prompts "Type a command: "
; - accepts commands:
;     PING           -> "PONG\n"
;     ECHO <text>    -> "<text>\n"
;     REVERSE <text> -> reversed text + "\n"
;     EXIT           -> "Goodbye!\n" and close connection (child exits)
; Parent forks per connection, child handles client loop.
;
; Syscalls used: socket(41), bind(49), listen(50), accept(43),
; fork(57), read(0), write(1), close(3), exit(60)
;
; Assemble & link:
; nasm -f elf64 asm20.asm -o asm20.o
; ld asm20.o -o asm20

section .data
    listen_msg db "Listening on port 4242", 10
    listen_len  equ $-listen_msg

    prompt db "Type a command: "
    prompt_len equ $-prompt

    pong db "PONG",10
    pong_len equ $-pong

    goodbye db "Goodbye!",10
    goodbye_len equ $-goodbye

    ; constants for sockaddr_in (16 bytes)
    ; struct sockaddr_in {
    ;   sa_family (2 bytes), sin_port (2 bytes, network order),
    ;   sin_addr (4 bytes), sin_zero (8 bytes)
    ; }
    ; AF_INET = 2 -> dw 2 => bytes 02 00
    ; port 4242 = 0x1092 -> network bytes 10 92.
    ; To get bytes 10 92 in memory on little-endian, store word 0x9210
    sockaddr:
        dw 2              ; sin_family = AF_INET (02 00)
        dw 0x9210         ; sin_port (network order bytes 10 92)
        dd 0              ; sin_addr = INADDR_ANY (0)
        dq 0              ; sin_zero 8 bytes zero

section .bss
    buf resb 512         ; buffer pour lecture des clients
    tmp resb 512         ; buffer temporaire pour opérations

section .text
    global _start

_start:
    ; Create socket: socket(AF_INET, SOCK_STREAM, 0)
    mov rax, 41          ; sys_socket
    mov rdi, 2           ; AF_INET
    mov rsi, 1           ; SOCK_STREAM
    xor rdx, rdx         ; protocol = 0
    syscall
    cmp rax, 0
    jl _exit_err         ; fail
    mov r12, rax         ; r12 = listen_fd

    ; bind(listen_fd, &sockaddr, 16)
    mov rdi, r12         ; fd
    lea rsi, [rel sockaddr]
    mov rdx, 16
    mov rax, 49          ; sys_bind
    syscall
    cmp rax, 0
    jl _close_fd_exit

    ; listen(listen_fd, 128)
    mov rdi, r12
    mov rsi, 128
    mov rax, 50          ; sys_listen
    syscall
    cmp rax, 0
    jl _close_fd_exit

    ; print "Listening on port 4242\n"
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel listen_msg]
    mov rdx, listen_len
    syscall

.accept_loop:
    ; accept - blocking
    ; accept(listen_fd, NULL, NULL)
    mov rax, 43          ; sys_accept
    mov rdi, r12         ; listen fd
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .accept_loop      ; on error, continue

    mov r13, rax         ; r13 = client_fd

    ; fork()
    mov rax, 57          ; sys_fork
    syscall
    cmp rax, 0
    je .child_process    ; child (rax == 0)
    ; parent:
    ; close client fd in parent and continue accepting
    mov rdi, r13
    mov rax, 3           ; sys_close
    syscall
    jmp .accept_loop

.child_process:
    ; child: r13 contains client fd
    ; handle client loop: prompt -> read -> respond until EXIT or EOF

.handle_loop:
    ; write prompt
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel prompt]
    mov rdx, prompt_len
    syscall

    ; read up to 512 bytes
    mov rax, 0
    mov rdi, r13
    lea rsi, [buf]
    mov rdx, 512
    syscall
    cmp rax, 0
    jle .child_exit      ; 0 -> client closed or error -> exit child
    mov r14, rax         ; r14 = bytes_read

    ; normalize buffer: replace CRLF? We'll treat newline as terminator.
    ; ensure buffer has a 0 terminator at bytes_read (safe)
    mov rcx, r14
    dec rcx
    mov al, [buf+rcx]
    cmp al, 10
    jne .strip_none
    ; if last char is newline, set bytes_read-- (we'll treat as length)
    ; but we keep data in buf; mark terminator
    mov byte [buf+rcx], 0
    mov r14, rcx
    jmp .parse_cmd
.strip_none:
    mov byte [buf + r14], 0

.parse_cmd:
    ; Now buffer is NUL-terminated, length in r14
    ; Compare commands:
    ; check if starts with "PING"
    lea rsi, [buf]
    mov rdi, rsi
    ; compare first 4 bytes
    mov eax, dword [rsi]       ; load 4 bytes
    cmp eax, 0x474e4950        ; 'P' 'I' 'N' 'G' little-endian value?
    ; careful: memory bytes order: 'P' 'I' 'N' 'G' -> 0x50494E47? Let's compute properly.
    ; We'll compare by bytes manually to avoid endianness mistakes.

    ; Instead: do byte comparisons
    mov al, [buf]
    cmp al, 'P'
    jne .check_echo
    mov al, [buf+1]
    cmp al, 'I'
    jne .check_echo
    mov al, [buf+2]
    cmp al, 'N'
    jne .check_echo
    mov al, [buf+3]
    cmp al, 'G'
    jne .check_echo
    ; matched PING (maybe with trailing NUL or nothing)
    ; respond "PONG\n"
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel pong]
    mov rdx, pong_len
    syscall
    jmp .handle_loop

.check_echo:
    ; check ECHO (starts with "ECHO ")
    mov al, [buf]
    cmp al, 'E'
    jne .check_reverse
    mov al, [buf+1]
    cmp al, 'C'
    jne .check_reverse
    mov al, [buf+2]
    cmp al, 'H'
    jne .check_reverse
    mov al, [buf+3]
    cmp al, 'O'
    jne .check_reverse
    mov al, [buf+4]
    cmp al, ' '
    jne .check_reverse
    ; matched "ECHO "
    ; write the rest of the buffer (buf+5) followed by '\n' if not present
    ; length = r14 - 5
    mov rdx, r14
    cmp rdx, 5
    jbe .echo_empty
    sub rdx, 5
    lea rsi, [buf+5]
    mov rax, 1
    mov rdi, r13
    syscall                ; write rdx bytes from rsi
    ; ensure newline
    ; write newline
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel prompt]  ; reuse memory for newline byte: we'll write '\n' directly
    ; but prompt contains more; easier: write single '\n' from stack
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel newline_byte]
    mov rdx, 1
    syscall
    jmp .handle_loop

.echo_empty:
    ; nothing after ECHO, just write newline
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel newline_byte]
    mov rdx, 1
    syscall
    jmp .handle_loop

.check_reverse:
    ; check REVERSE (starts with "REVERSE ")
    mov al, [buf]
    cmp al, 'R'
    jne .check_exit
    mov al, [buf+1]
    cmp al, 'E'
    jne .check_exit
    mov al, [buf+2]
    cmp al, 'V'
    jne .check_exit
    mov al, [buf+3]
    cmp al, 'E'
    jne .check_exit
    mov al, [buf+4]
    cmp al, 'R'
    jne .check_exit
    mov al, [buf+5]
    cmp al, 'S'
    jne .check_exit
    mov al, [buf+6]
    cmp al, 'E'
    jne .check_exit
    mov al, [buf+7]
    cmp al, ' '
    jne .check_exit
    ; matched "REVERSE "
    ; compute length of text = r14 - 8
    mov rdx, r14
    cmp rdx, 8
    jbe .reverse_empty
    sub rdx, 8
    lea rsi, [buf+8]
    ; reverse into tmp buffer
    mov rdi, rsi       ; rdi = pointer to input start
    mov rbx, rdx       ; rbx = length
    xor rcx, rcx       ; rcx = index_out = 0
    dec rbx
.rev_loop:
    mov al, [rdi + rbx]
    mov [tmp + rcx], al
    inc rcx
    dec rbx
    cmp rbx, -1
    jg .rev_loop
    ; write tmp (rcx bytes)
    mov rax, 1
    mov rdi, r13
    lea rsi, [tmp]
    mov rdx, rcx
    syscall
    ; write newline
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel newline_byte]
    mov rdx, 1
    syscall
    jmp .handle_loop

.reverse_empty:
    ; nothing after REVERSE, just newline
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel newline_byte]
    mov rdx, 1
    syscall
    jmp .handle_loop

.check_exit:
    ; check EXIT
    mov al, [buf]
    cmp al, 'E'
    jne .unknown_cmd
    mov al, [buf+1]
    cmp al, 'X'
    jne .unknown_cmd
    mov al, [buf+2]
    cmp al, 'I'
    jne .unknown_cmd
    mov al, [buf+3]
    cmp al, 'T'
    jne .unknown_cmd
    ; matched EXIT (ignore trailing)
    ; send "Goodbye!\n" then close and exit child
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel goodbye]
    mov rdx, goodbye_len
    syscall

    ; close client fd
    mov rax, 3
    mov rdi, r13
    syscall

    ; child exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

.unknown_cmd:
    ; Unknown command: just send newline and continue
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel newline_byte]
    mov rdx, 1
    syscall
    jmp .handle_loop

.child_exit:
    ; client closed or read error -> close fd and exit child
    mov rax, 3
    mov rdi, r13
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall

_close_fd_exit:
    mov rdi, r12
    mov rax, 3
    syscall
_exit_err:
    mov rax, 60
    mov rdi, 1
    syscall

section .data
    newline_byte db 10
