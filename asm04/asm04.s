section .bss
	input resb 6

section .text
   	global _start

_start:
	mov rax, 0
	mov rdi, 0
	mov rsi, input
	mov rdx, 6
	syscall

   	mov ax, [input]
   	and ax, 1
   	jz evnn
   	jmp outprog

evnn:
   	mov rax, 60
	mov rdi, 0
	syscall

outprog:
	mov rax, 60
	mov rdi, 1
	syscall
