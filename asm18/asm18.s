global _start

section .data
    	server_ip db 127,0,0,1
    	server_port dw 1337
    	message db 'message: "Hello, client!"',0
	message_len equ $-message
	timeout_message db "Timeout: no response from server", 10
	timeout_len equ $-timeout

section .bss
    	sock resb 16
	buf resb 1024

section .text
_start:
   
    mov rax, 41               ; sys_socket
    mov rdi, 2                ; AF_INET
    mov rsi, 1                ; SOCK_STREAM
    mov rdx, 0                ; protocol
    syscall

	cmp rax, 0
	js fail
    	mov r12, rax

    	lea rdi, [sock]
    	mov word [rdi], 2           ; AF_INET
    	mov word [rdi+2], 0x3905     ; port 12345
    	mov dword [rdi+4], 0x0100007F ; 127.0.0.1
	mov qword [rdi + 8], rax

    	mov rax, 44
	mov rdi, r12
	lea rsi, [message]
	mov rdx, message_len
	mov r10, 0
	lea r8, [sock]
	mov r9, r16
	syscall

	cmp rax, 0
	js fail	


    	mov qword [buf], 5
	xor qword [buf + 8], 0

	mov rax, 54
	mov rdi, r12
	mov rsi, 1
	mov rdx, 20
	lea r10, [buf]
	mov r8, 16
	syscall
	
	cmp rax, 0
	js fail

	mov rax, 45
	mov rdi, r12
	lea rsi, [buf]
	mov rdx, 128
	mov r10, 0
	mov r8, 0
	mov r9, 0
	syscall


	cmp rax, 0
	jle timeout
	jmp success


success:
	mov rdx, rax
	mov rax, 1
	mov rdi, 1
	lea rsi, [buf]
	syscall

	mov rax, 3
	mov rdi, 12
	syscall

	mov rax, 60
	mov rdi, 0
	syscall

timeout:
	mov rax, 3
	mov rdi, r12
	syscall

	mov rax, 1
	mov rdi, 1
	lea rsi, [timeout_message]
	mov rdx, timeout_len
	syscall

	mov rax, 60
	mov rdi, 1
	syscall

fail:
	mov rax, 3
	mov rdi, r12
	syscall

	mov rax, 60
	mov rdi, 1
	syscall
