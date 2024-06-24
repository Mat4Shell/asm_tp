section .data
    num resb 6

section .text
    global _start

_start:
	mov rax, 0
	mov rdi, 0
	mov rsi, num
	mov rdx, 6
	syscall

prime:
	mov rax, 60
	mov rdi, 0
	syscall

exit_program:
	mov rax, 60
	mov rdi, 1
	syscall
